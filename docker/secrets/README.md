# Secrets directory
If you're expect to sign the debs build by this Dockerfile, you'll need to
put an armored private key into the `gpgkey` file in this directory.  To
create the key:

```
$ gpg --armor --export-secret-key > secrets/gpgkey
```

The key needs to operate without password, so you should probably limit your
uses of this key to signing debs for upload.
