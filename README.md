# fixhomeperms.sh
<p>
quick and dirty script to fix permissions for all files and directories under $HOME.
<p>
This little tool makes use of find and xargs to boost the operations and it's faster than the "find -exec chmod" combo.
<p>
Yes, you can run the same commands manually everytime but this script features options to fix all permissions on your $HOME as they should be... This is specially usefull when copying files from other systems and permissions on directories and files get garbled, and you end up with things like:<p>
  drwxrwxrwx directory<p>
  -rwxrwxrwx file<p>
    
 everywhere... 

## considerations
<p>
The following is assumed:<p>
  1. directories are to be set as rwxr-xr-x (octal: 755)<p>
  2. non-executable files (i.e. PDFs, txt, etc) are to be set as rw-r--r-- (octal: 644)<p>
  3. executable files (i.e. shell scripts, Perl, Python, Ruby and RUN files) are to be set as rwxr-xr-x (octal: 755)<p>
<p>
Feel free to modify the script to suit your needs<p>

## usage
<p>
Run fixhomeperms.sh without arguments or with -h to see the instructions.
<p>

# disclaimer
<p>
This script is provided "AS IS" and the author is not to be held responsible for any damage caused by the use or misuse thereof.
<p>
  
