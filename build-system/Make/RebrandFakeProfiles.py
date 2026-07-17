import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from BuildEnvironment import run_executable_with_output
from GenerateProfiles import (
    setup_temp_keychain,
    cleanup_temp_keychain,
    get_signing_identity_from_p12,
    get_certificate_base64_from_p12,
)

# Rewrites the base bundle id embedded in the fake-codesigning provisioning
# profiles (application-identifier, application-groups, iCloud, keychain, etc.)
# and re-signs each profile with the SelfSigned fake certificate. This lets the
# app be built under a custom bundle id (e.g. ru.shadowyohan.shadowgram) so it
# coexists with the App Store Telegram and its App Group entitlement stays
# consistent — which is what avoids the black screen a post-build re-bundling
# tool causes when it remaps the id inconsistently.


def rebrand_profile(path, old_id, new_id, certificate_data, signing_identity, keychain_name):
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
        'cms', '-S', '-k', keychain_name, '-N', signing_identity, '-i', parsed_plist_file, '-o', path
    ], check_result=True)

    os.unlink(parsed_plist_file)


def main():
    if len(sys.argv) != 5:
        print('Usage: RebrandFakeProfiles.py <profiles_dir> <certs_dir> <old_bundle_id> <new_bundle_id>')
        sys.exit(1)

    profiles_dir = sys.argv[1]
    certs_dir = sys.argv[2]
    old_id = sys.argv[3]
    new_id = sys.argv[4]

    p12_path = os.path.join(certs_dir, 'SelfSigned.p12')
    if not os.path.exists(p12_path):
        print('{} does not exist'.format(p12_path))
        sys.exit(1)

    certificate_data = get_certificate_base64_from_p12(p12_path, '')
    signing_identity = get_signing_identity_from_p12(p12_path, '')
    if not signing_identity:
        print('Could not extract signing identity from {}'.format(p12_path))
        sys.exit(1)

    print('Rebranding profiles {} -> {} (identity: {})'.format(old_id, new_id, signing_identity))
    keychain_name = setup_temp_keychain(p12_path, '')
    try:
        for file_name in sorted(os.listdir(profiles_dir)):
            if file_name.endswith('.mobileprovision'):
                print('Rebranding {}'.format(file_name))
                rebrand_profile(
                    path=os.path.join(profiles_dir, file_name),
                    old_id=old_id,
                    new_id=new_id,
                    certificate_data=certificate_data,
                    signing_identity=signing_identity,
                    keychain_name=keychain_name,
                )
    finally:
        cleanup_temp_keychain(keychain_name)
    print('Done.')


if __name__ == '__main__':
    main()
