# fixhomeperms.sh

Quick and dirty script to fix permissions for all files and directories under `$HOME`.

This little tool makes use of `find` and `xargs` to boost the operations and it's faster than the `find -exec chmod` combo.

Yes, you can run the same commands manually everytime but this script features options to fix all permissions on your `$HOME` as they should be... 

This is specially usefull when copying files from other systems and permissions on directories and files get garbled, and you end up with things like:

```
drwxrwxrwx directory
-rwxrwxrwx file
```
    
 everywhere... 

## considerations

The following is assumed:
  1. directories are to be set as `rwxr-xr-x` (octal: 0755)
  2. non-executable files (i.e. PDFs, txt, etc) are to be set as `rw-r--r--` (octal: 0644)
  3. executable files (i.e. shell scripts, Perl, Python, Ruby and RUN files) are to be set as `rwxr-xr-x` (octal: 0755)
  4. hidden directories and files are left untouched (thanks Drazenko Djuricic for the heads-up!)

Feel free to modify the script to suit your needs

## usage

```
./fixhomeperms.sh 
fixhomeperms.sh by Martin Mielke <martinm@rsysadmin.com>

Usage:  fixhomeperms.sh [-h] [-d] [-n] [-s] [-p] [-P] [-r] [-R] [-a]
        -h  Prints this help.
        -d  Fix permissions on directories (0755).
        -n  Fix permissions on non-exec files (0644).
        -s  Fix permissions on shell script files (0755).
        -p  Fix permissions on Perl files (0755).
        -P  Fix permissions on Python files (0755).
        -r  Fix permissions on Ruby files (0755).
        -R  Fix permissions on RUN files (0755).
        -a  Fix permissions on all executable files (.sh, .pl, .py, .rb, .run).
        -A  Fix all in one step, including directories and non-exec files.

```





# disclaimer

This script is provided "AS IS" and the author is not to be held responsible for any damage caused by the use or misuse thereof.

  
