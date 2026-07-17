import os
import re
import sys
import base64
import tempfile
import subprocess

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from BuildEnvironment import run_executable_with_output

# Rewrites the base bundle id embedded in the fake-codesigning provisioning
# profiles (application-identifier, application-groups, iCloud, keychain, etc.)
# and re-signs each profile with the fake self-signed certificate. This lets the
# app be built under a custom bundle id (e.g. ru.shadowyohan.shadowgram) so it
# coexists with the App Store Telegram and its App Group entitlement stays
# consistent — which avoids the black screen a post-build re-bundling tool causes
# when it remaps the id inconsistently.
#
# The signing identity and certificate are read from the keychain that
# ImportCertificates.py already populated (temp.keychain, empty p12 password),
# rather than parsed from the p12 with openssl — the runner ships LibreSSL, whose
# `openssl pkcs12 -legacy` output is not usable.

KEYCHAIN_NAME = 'temp.keychain'
IDENTITY_HINT = 'Telegram FZ-LLC'


def find_signing_identity():
    for arguments in (['find-identity', '-v', '-p', 'codesigning'],
                      ['find-identity', '-p', 'codesigning'],
                      ['find-identity']):
        out = run_executable_with_output('security', arguments=arguments, check_result=False) or ''
        names = re.findall(r'"([^"]+)"', out)
        for name in names:
            if IDENTITY_HINT in name:
                return name
        if names:
            return names[0]
    return None


def certificate_base64(identity):
    pem = run_executable_with_output('security', arguments=['find-certificate', '-c', identity, '-p'], check_result=True)
    proc = subprocess.Popen(['openssl', 'x509', '-outform', 'DER'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    der, _ = proc.communicate(pem.encode('utf-8') if isinstance(pem, str) else pem)
    return base64.b64encode(der).decode('utf-8')


def rebrand_profile(path, old_id, new_id, certificate_data, signing_identity):
    parsed_plist = run_executable_with_output('security', arguments=['cms', '-D', '-i', path], check_result=True)
    parsed_plist = parsed_plist.replace(old_id, new_id)

    parsed_plist_file = tempfile.mktemp()
    with open(parsed_plist_file, 'w+') as file:
        file.write(parsed_plist)

    while True:
        run_executable_with_output('plutil', arguments=['-remove', 'DeveloperCertificates.0', parsed_plist_file], check_result=False)
        check = run_executable_with_output('plutil', arguments=['-extract', 'DeveloperCertificates.0', 'raw', parsed_plist_file], check_result=False)
        if check is None or 'Could not' in str(check):
            break

    run_executable_with_output('plutil', arguments=['-insert', 'DeveloperCertificates.0', '-data', certificate_data, parsed_plist_file])
    run_executable_with_output('plutil', arguments=['-remove', 'DER-Encoded-Profile', parsed_plist_file], check_result=False)

    run_executable_with_output('security', arguments=[
        'cms', '-S', '-k', KEYCHAIN_NAME, '-N', signing_identity, '-i', parsed_plist_file, '-o', path
    ], check_result=True)

    os.unlink(parsed_plist_file)


def main():
    if len(sys.argv) != 5:
        print('Usage: RebrandFakeProfiles.py <profiles_dir> <certs_dir> <old_bundle_id> <new_bundle_id>')
        sys.exit(1)

    profiles_dir = sys.argv[1]
    old_id = sys.argv[3]
    new_id = sys.argv[4]

    signing_identity = find_signing_identity()
    if not signing_identity:
        print('Could not find a signing identity in the keychain')
        sys.exit(1)
    print('Using signing identity: {}'.format(signing_identity))

    certificate_data = certificate_base64(signing_identity)

    for file_name in sorted(os.listdir(profiles_dir)):
        if file_name.endswith('.mobileprovision'):
            print('Rebranding {} ({} -> {})'.format(file_name, old_id, new_id))
            rebrand_profile(
                path=os.path.join(profiles_dir, file_name),
                old_id=old_id,
                new_id=new_id,
                certificate_data=certificate_data,
                signing_identity=signing_identity,
            )
    print('Done.')


if __name__ == '__main__':
    main()
