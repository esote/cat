STDIN		equ 0
STDOUT		equ 1
BUFSIZE		equ 4096
O_RDONLY	equ 0

[section .text]
[global _start]

_start:
	xor r14, r14		; error value, r14 is callee-saved

	mov r15, [rsp]		; argc, r15 is callee-saved
	mov rbp, [rsp + 16]	; argv

	cmp r15, 1
	dec r15
	jle stdin		; read stdin if argc <= 1
	dec r15

	mov rax, rbp
open:
	cmp byte [rax], 45
	jne ropen
	cmp byte [rax + 1], 0	; *argv is "-"
	je stdin

ropen:
	mov rdi, rax
	mov rax, 2		; sys_open
	xor rsi, rsi
	mov rdx, O_RDONLY
	syscall

	test rax, rax		; open failed
	mov rcx, 1
	cmovs r14, rcx
	js next

	mov rbx, rax		; rbx stores fd
read:
	xor rax, rax		; sys_read
	mov rdi, rbx
	mov rsi, buffer
	mov rdx, BUFSIZE
	syscall

	test rax, rax
	mov rcx, 1
	cmovs r14, rcx
	js next			; read failed
	je close		; read complete

	mov rdx, rax		; read amount
	mov rdi, STDOUT
write:
	mov rax, 1		; sys_write
	syscall

	test rax, rax
	mov rcx, 1
	cmovs r14, rcx
	js close		; write failed

	sub rdx, rax

	test rdx, rdx
	jne write		; more to write

	jmp read		; write complete

close:
	cmp rbx, STDIN		; don't close standard input
	je next

	mov rax, 3		; sys_close
	mov rdi, rbx
	syscall

	test rax, rax
	mov rcx, 1
	cmovs r14, rcx

next:
	cmp r15, 0
	je exit

	inc rbp
	cmp byte [rbp], 0	; next in argv
	jne next

	dec r15

	inc rbp
	cmp byte [rbp], 0
	mov rax, rbp
	jne open

exit:
	mov rax, 3		; sys_close
	mov rdi, STDOUT		; close stdout, allow SIGPIPE
	syscall

	mov rdi, r14
	mov rax, 60		; sys_exit
	syscall

stdin:
	mov rbx, STDIN
	jmp read

[section .bss]
	buffer: resb BUFSIZE	; 4096-byte buffer
