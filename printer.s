section .data 
    format_target_position: db "target position: %.2f,%.2f", 10, 0
    format_drone_data: db "drone data: index_%d , x_%.2f , y_%.2f , alpha_%.2f , speed_%.2f , number_of_destroyed_target_%d", 10, 0
    tmp: dd 0.0
    double_alpha: dq 0.0
    double_x: dq 0.0
    double_y: dq 0.0
    double_speed: dq 0.0
    double_target_x: dq 0.0
    double_target_y: dq 0.0

section .text
    global run_printer
    extern do_resume
    extern Resume
    extern printf
    extern drone_num_target_destroyed
    extern drone_data_array
    extern x_target
    extern y_target
    extern number_of_drones
    extern sch_co
    extern printer_co
    extern Curr
run_printer:

    finit

    fld dword[x_target]
    fstp qword[double_target_x]

    fld dword[y_target]
    fstp qword[double_target_y]

    push dword [double_target_y+4]
    push dword[double_target_y]
    push dword[double_target_x+4]
    push dword[double_target_x]
    push format_target_position
    call printf
    add esp, 20

    mov edi , 0                     ; counter for the loop

    drone_loop:
        cmp edi, dword [number_of_drones]
        je end_drone_loop
        mov ebx , dword [drone_data_array]
        mov eax , edi
        imul eax, 24                ; each drone data is 24 bytes
        add ebx, eax                ; pointer to the position in the drone data array
        cmp dword [ebx+20], 1
        je print_drone
        jmp end_print_one_drone
        
        print_drone:
        fld dword [ebx+8] 
        mov dword [tmp], 180
        fild dword [tmp]
        fmul  
        fldpi
        fdiv

        fstp qword [double_alpha]
        
        fld dword [ebx+12]
        fstp qword [double_speed]

        fld dword [ebx+4]
        fstp qword [double_y]
        
        fld dword [ebx]
        fstp qword [double_x]
        inc edi
        push dword  [ebx+16]

        push dword [double_speed+4]
        push dword [double_speed]

        push dword [double_alpha+4]
        push dword [double_alpha]

        push dword [double_y+4]
        push dword [double_y]

        push dword [double_x+4]
        push dword [double_x]

        push edi

        push format_drone_data
        call printf
        add esp, 44 
        dec edi

        end_print_one_drone:
            inc edi
            jmp drone_loop 
        
    end_drone_loop:
            mov esi, dword printer_co
            mov dword [Curr], esi
            mov dword ebx, sch_co
            call Resume
            jmp run_printer
 

    