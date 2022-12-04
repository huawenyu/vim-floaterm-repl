# REPL - Support markdown code fence
Run repl code in the floating/popup window.

### demo
![markdown](./screenshot/markdown_demo.gif)

# Install

The plugin depend on [vim-floaterm](https://github.com/voldikss/vim-floaterm).~
The plugin fork from [vim-floaterm-repl](https://github.com/windwp/vim-floaterm).~

using vim-plug

``` vim
Plug 'voldikss/vim-floaterm'
Plug 'huawenyu/vim-floaterm-repl'
```

# Usage
* run a part of code in script file
  > - Select code and run `:FloatermRepl` 

* run a block code in markdown file with argument passing
  > - Put cursors in codeblock and run :FloatermRepl (you don't need to select it).
  > - Passing argument to script in codeheader [see](#demo)

* the markdown code fence sample, run `:FloatermRepl`
  - support auto scan & eval the shell command
  - workflow:
    1. the plugin auto copy the code-fence into a independent `{file}`, extension with the filetype,
    2. parse the `{file}` to the `runner.sh`, can be customize by `g:floaterm_repl_runner`,
    3. the `runner.sh` will simple parse the `{file}`, take action according to the filetype,
    4. the `runner.sh` auto scan & eval all command beginswith `>>>,`
  - there have two builtin variables:
    + `{file}`     the file-full-path, i.e. `/tmp/vim_a.c`
    + `{fileout}`  the make output binary file, i.e. `/tmp/vim_a.out`

```c  Tryme - put the cursor, and trigger the map to call `:FloatermRepl`
/*
https://linuxhint.com/using_mmap_function_linux/
mmap used to Writing file

size-of
     file   map  write unmap
     1024  2048  2048  2048

>>> {fileout}  1024  2048  2048  2048
>>> echo Normal

>>> {fileout}  1024  2048  2048  3048
>>> echo OK: unmap more size

>>> {fileout}  1024  2048  2048  5048
>>> echo ERROR: unmap > 4K page (Segmentation-fault)

>>> {fileout}  1024  2048  4096  2048
>>> echo OK: write < 4K-page

>>> {fileout}  1024  2048  4097  2048
>>> echo ERROR: write > 4K page (Bus error)

>>> size {fileout}
>>> ls -l {file}
*/

#include <stdio.h>
#include <sys/mman.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

int main(int argc, char *argv[])
{
	const char *filepath = "/tmp/no_use_map.txt";
	int file_size, map_size, write_size, unmap_size;
	int ret = 0;

	file_size  = atoi(argv[1]);
	map_size   = atoi(argv[3]);
	write_size = atoi(argv[3]);
	unmap_size = atoi(argv[4]);

	unlink(filepath);
	int fd = open(filepath, O_RDWR | O_CREAT);
	if (fd < 0) {
		perror("file open fail");
		goto out;
	}

	struct stat statbuf;
	int err = fstat(fd, &statbuf);
	if (err < 0) {
		perror("file fstat fail");
		goto out;
	}
	// statbuf.st_size

	ftruncate(fd, file_size);
	char *ptr = mmap(NULL, map_size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
	if (ptr == MAP_FAILED) {
		perror("Mapping Failed\n");
		ret = 1;
	}
	close(fd);

	for (int i=0; i < write_size; i++) {
		ptr[i] = 'A';
	}

	err = munmap(ptr, unmap_size);
	if (err != 0) {
		perror("UnMapping Failed\n");
		ret = 1;
	}

out:
	unlink(filepath);
	return ret;
}
```

## Key map
``` vim
nnoremap <leader>uc :FloatermRepl<CR>
vnoremap <leader>uc :FloatermRepl<CR>
```
 Press `<ESC>` or `q` to exit in floaterm window

## Configuration

* current support python, go, c/c++, javascript
* add support for your language by modify runner script

```vim
let g:floaterm_repl_runner= "/home/vim/test/runner.sh"
```

* Sample runner.sh
 ``` bash 
#!/usr/bin/env bash
filetype=$1
filepath=$2
shift
shift
params=$@
echo "Start $filetype $filepath"
echo "====================="
case $filetype in
  javascript | js)
     node $filepath $params
    ;;

  bash | sh)
     bash $filepath $params
    ;;

  go )
     go run $filepath $params
    ;;
  python | python3) 
     python3 $filepath $params
    ;;

  *)
    echo -n "unknown"
    ;;
esac
echo "====================="

 ```
