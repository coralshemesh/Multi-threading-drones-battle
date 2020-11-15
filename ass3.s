
%macro sscanfTheArgs 3
    push %1
    push %2
    push %3
    call sscanf
	add esp, 12				;remove params from stack
%endmacro 

section .rodata
    DroneStackSize: dd 16384*2
    stack_size: equ 16*1024
    format: db "%X",10,0

section .bss
    global Curr
    global stack_pointer_value
    global sp_main
    LFSR: resb 2
    Curr: resd 1
    stack_pointer_value: resd 1
    sp_main: resd 1 
    targetStack: resb stack_size               ;resb for each co-routine stack
    printerStack: resb stack_size
    schedulerStack: resb stack_size
    droneStack: resb stack_size

section .data 
    global max_distance
    global LFSR
    global sch_cycle
    global K_steps_before_print
    global random_number
    global drone_data_array
    global drone_pointer_array
    global number_of_drones
    global number_of_active_drones
    global target_co
    global printer_co
    global drone_co
    global sch_co
    global sch_co
    global curr_drone_co
    max_distance: dd 0
    sch_cycle: dd 0
    K_steps_before_print: dd 0
    random_number: dd 0
    drone_data_array: dd 0
    drone_pointer_array: dd 0
    number_of_drones: dd 0
    number_of_active_drones: dd 0 
    fmt: db "%d", 10, 0
    target_co: dd run_target
               dd targetStack+stack_size
    printer_co: dd run_printer
                dd printerStack+stack_size
    drone_co: dd run_drone
              dd droneStack+stack_size
    sch_co: dd run_scheduler
            dd schedulerStack+stack_size
    curr_drone_co: dd 0 
    X: dd 0.0
    Y: dd 0.0
    alpha: dd 0.0
    speed: dd 0.0

   
section .text   
    global main
    global calculate_random_number
    global start_co_routine
    global end_co_routine
    global free_arrays
    extern run_drone
    extern run_target
    extern run_printer
    extern run_scheduler
    extern malloc
    extern create_target
    extern do_resume
    extern sscanf
    extern printf
    extern free
    
%macro printMemory 1
		push dword [%1]
        push format
		call printf				
		add esp, 8            	
%endmacro
%macro printRegister 1
		push %1
        push format
		call printf				
		add esp, 8            	
%endmacro
main:
    mov ebp, esp 

    finit                   ;init the floating point stack

;**************************get args*****************************
    mov ebx, dword[ebp+8]         ; ebp+8 is argc and ebp+12 is argv 
                                                        
    mov ecx , dword [ebx+4]
    sscanfTheArgs number_of_drones, fmt, ecx

    mov ecx , dword [ebx+4]
    sscanfTheArgs number_of_active_drones, fmt, ecx

    mov ecx , dword [ebx+8]
    sscanfTheArgs sch_cycle, fmt, ecx

    mov ecx , dword [ebx+12]
    sscanfTheArgs K_steps_before_print, fmt, ecx

    mov ecx , dword [ebx+16]
    sscanfTheArgs max_distance, fmt, ecx

    mov ecx , dword [ebx+20]
    sscanfTheArgs LFSR, fmt, ecx

;************************initial co-routine********************************************************
    call initial_board
    call initial_target
    call initial_printer
    call initial_scheduler
    call initial_drone
    call start_co_routine
exit:
    mov ebx, 0
    mov eax, 1 
    int 0x80 
    nop
    ret

;**************************END OF MAIN FUNCTION************************************

initial_board:
    call create_target
    ret
;****************************initial target***********************************
initial_target:
    mov dword ebx,  target_co
    mov eax, dword [ebx]            ; ebx hold the target co struct which points to the function 
    mov dword [stack_pointer_value], esp 
    mov esp , dword [ebx+4]          ; now esp 
    push eax 
    pushfd
    pushad
    mov dword [ebx+4], esp
    mov esp, dword [stack_pointer_value]
    ret 

;*************************initial printer**********************************
initial_printer:
    mov dword ebx,  printer_co
    mov eax, dword [ebx]            ; ebx hold the target co struct which points to the function 
    mov dword [stack_pointer_value], esp 
    mov esp , dword [ebx+4]          ; now esp 
    push eax 
    pushfd
    pushad
    mov dword [ebx+4], esp
    mov esp, dword [stack_pointer_value]
    ret 

;**************************initial schedular******************************
initial_scheduler:
    mov dword ebx,  sch_co
    mov eax, dword [ebx]            ; ebx hold the target co struct which points to the function 
    mov dword [stack_pointer_value], esp 
    mov esp , dword [ebx+4]          ; now esp 
    push eax 
    pushfd
    pushad
    mov dword [ebx+4], esp
    mov esp, dword [stack_pointer_value]
    ret 

;*****************************initial drone************************************
initial_drone:

    initial_drone_pointer_array:
        mov dword eax, [number_of_drones]       
        imul eax, 8 

        push eax
        call malloc                                     ; we have a pointer array of drone each cell has to pointers one for the func and one for the stack 
        add esp, 4
        
        mov dword [drone_pointer_array], eax
        mov edi , 0                                     ; counter for the loop 

        loop_init_drone:
            cmp edi , dword [number_of_drones]
            je end_initial_drone_pointer_array
            mov eax, edi
            imul eax, 8
            mov ebx , dword [drone_pointer_array]
            add ebx, eax
            mov dword ecx , run_drone
            mov dword[ebx], ecx
                               
                               ; malloc for each drone stack
            push stack_size
            call    malloc
            add     esp, 4

            mov dword[ebx+4], eax                       ; ebx+4 points to the new allocated space
            add dword [ebx+4], stack_size
            mov ecx, dword [ebx]                        ; ebx hold the pointer to the function
            mov dword [stack_pointer_value], esp 
            mov esp , dword [ebx+4]                     ; now esp points to the drone co-rutine stack
            push ecx 
            pushfd
            pushad
            mov dword [ebx+4], esp
            mov esp, dword [stack_pointer_value]
            inc edi
            jmp loop_init_drone

        end_initial_drone_pointer_array:
            
            initial_drone_data_array:
                mov eax, dword[number_of_drones]       
                imul eax, 24                    ; X Y alpha speed targets isActive - 4 bytes each so 4*6 = 24
                
                push eax
                call malloc                     ; we have a pointer array of drone each cell has to pointers one for the func and one for the stack 
                add esp, 4
                
                mov dword [drone_data_array], eax
                mov edi , 0                      ; counter for the loop 

                loop_init_drone_data:
                    cmp edi , dword [number_of_drones]
                    je end_initial_drone_data_array 
                    mov eax, edi
                    imul eax, 24                       ;eax points to the next drone data
                    mov ebx, dword[drone_data_array]
                    add ebx, eax
                ;************************calculate x random value for drone position**************************
                    call calculate_random_number
                    fild dword [random_number]          ; st(0) = random_number as float point, fild convert int to float
                    mov dword [random_number], 100      ; scale from [0, 100] in total 100 
                    fimul dword [random_number]         ; st(0)* 100    
                    mov dword [random_number], 65535    ; div random number in MAX_INT
                    fidiv dword [random_number]         ; st(0) = random_number* 100 / 65535
                    fstp dword [X]                      ; store st(0) in X
                ;************************calculate Y random value for drone position**************************
                    
                    call calculate_random_number
                    fild dword [random_number]          ; st(0) = random_number as float point, fild convert int to float
                    mov dword [random_number], 100      ; scale from [0, 100] in total 100 
                    fimul dword [random_number]         ; st(0)* 100    
                    mov dword [random_number], 65535    ; div random number in MAX_INT
                    fidiv dword [random_number]         ; st(0) = random_number* 100 / 65535
                    fstp dword [Y] 
                                         ; store st(0) in Y

                ;************************calculate random alpha for drone*******************************************

                    call calculate_random_number
                    fild dword [random_number]          ; st(0) = random_number as float point, fild convert int to float
                    mov dword [random_number], 360      ; scale from [0, 360] in total 360 
                    fimul dword [random_number]         ; st(0)* 360    
                    mov dword [random_number], 65535    ; div random number in MAX_INT
                    fidiv dword [random_number]         ; st(0) = random_number* 120 / 65535
                    fldpi                               ; push pi into the float stack  
                    fmul                                ; according to the formula deg* pi / 180 
                    mov dword [random_number], 180 
                    fidiv dword [random_number]    
                    fstp dword [alpha]                  ; store st(0) in delta_alpha

                ;************************calculate speed random value************************************************
                    call calculate_random_number
                    fild dword [random_number]          ; st(0) = random_number as float point, fild convert int to float
                    mov dword [random_number], 100       ; scale from [0, 100] in total 100
                    fimul dword [random_number]         ; st(0)* 100    
                    mov dword [random_number], 65535    ; div random number in MAX_INT
                    fidiv dword [random_number]         ; st(0) = random_number* 100 / 65535
                    fstp dword [speed]                  ; store st(0) in speed

                ;**********************move from memory fields to the array*******************************************
                    mov ecx, dword[X] 
                    mov dword[ebx], ecx
                    mov ecx, dword[Y]
                    mov dword[ebx+4], ecx
                    mov ecx, dword[alpha]
                    mov dword[ebx+8], ecx
                    mov ecx, dword[speed]
                    mov dword[ebx+12], ecx
                    mov dword[ebx+16], 0                ; num of targets start with 0
                    mov dword[ebx+20], 1                ; the drone is now active

                    inc edi
                    jmp  loop_init_drone_data
                                
                end_initial_drone_data_array:
                    ret


;*************************************start co routine*****************************
start_co_routine:
    mov dword [sp_main], esp
    mov dword ebx, sch_co
    jmp do_resume

;*************************************end co routine*****************************
end_co_routine:
    call free_arrays
    mov esp, dword [sp_main]
    popad
    jmp exit


;*************************func to calculate LFSR random number*************************************
calculate_random_number:    
    pushad
    mov edx , 0                  ; count 16 loops
    mov dword [random_number], 0 

    xor ebx, ebx
    xor eax, eax
    mov ax, word [LFSR]

    calc_loop:
    cmp edx, 16 
    je end_calculate_random_number
    mov bx, 0x1  
    mov cx, 0x4                 
    and bx,ax
    and cx,ax
    shr cx,2
    xor cx,bx
    mov bx , 0x8
    and bx, ax
    shr bx,3
    xor cx, bx
    mov bx, 0x20

    and bx, ax
    shr bx,5
    xor cx, bx
    shr ax, 1
    shl bx, 15
    or ax, bx
    inc edx
    jmp calc_loop

    end_calculate_random_number:
        mov word [LFSR], ax
        mov dword [random_number], eax
        popad
        ret



free_arrays:

        mov ebx, dword[drone_data_array]
        push ebx
        call free
        add esp, 4
    
    mov ebx, dword[drone_pointer_array]
    push ebx
    call free
    add esp, 4
    ret



