
section .rodata
    format: db "%X", 10,0
    format_winner: db "the winner is drone: %d", 10,0


section .data
    global curr_drone_index
    extern sch_cycle
    extern K_steps_before_print
    extern drone_data_array
    extern drone_pointer_array
    extern number_of_drones
    extern number_of_active_drones
    curr_drone_index: dd 0
    counter_loop: dd 0
    curr_drone_function: dd 0
    drone_min_target: dd 32768
    drone_min_target_index: dd 0
    steps_so_far: dd 0
    extern curr_drone_co
    extern printer_co
    extern Curr
    extern sch_co

section .text
        global run_scheduler
        global Resume
        global do_resume 
        extern printf
        extern run_drone
        extern end_co_routine
        
run_scheduler:
        mov eax, dword [counter_loop]                                   ; eax is the counter of the loop
        mov ebx, dword [number_of_drones]     
        cdq
        idiv ebx
        mov dword [curr_drone_index], edx
        xor eax, eax
        mov eax, edx                                       ; put the curr_drone_index in eax 
        imul eax, 24                                        ; mul by 24 to get the right position in drine data array 
        mov ecx , dword [drone_data_array]
        add eax, ecx

        cmp dword [eax+20], 1                                ; check if drone is active 
        jne check_steps_even_though_drone_not_active

        switch_to_drone_co_routine:
        ;***********************switch to co routine*****************************
            mov eax, dword [curr_drone_index]
            imul eax, 8
            mov ebx , dword [drone_pointer_array]
            add dword ebx, eax

            mov dword [curr_drone_co], ebx                  ; this is the drone to be resumed 
            mov dword [Curr], sch_co                         ; Curr is the current co-routine
            call Resume 
            ;*******************check how many steps we did so far**********************

            check_steps_even_though_drone_not_active:
            xor ebx, ebx  
            xor eax, eax
            mov eax, dword [counter_loop]
            mov ebx, dword [K_steps_before_print] 
            cdq
            idiv ebx      ; div eax/ebx wich is counter_loop/ k_steps check if i mod k == 0
            ;************************check if we need to print*****************
            cmp edx , 0 
            jne not_time_to_print
            time_to_print:
                mov dword [Curr], sch_co   
                mov dword ebx, printer_co
                call Resume

            not_time_to_print:
            xor eax, eax
            ;*************************check first condotion*******************
            mov eax, dword [counter_loop]
            cmp eax, 0                                      ; if counter loop == 0 so we are in the first round - do not print !                                   
            je continue_loop
            mov ebx, dword [number_of_drones]               ; do i/N counter_loop / number of drones 
            cdq
            idiv ebx
            cmp edx, 0 
            je check_R_condition

            continue_loop:
            inc dword [counter_loop]
            ;*********************** check if we have a winner*******************
            cmp dword [number_of_active_drones], 1
            je find_winner
            jmp run_scheduler
            
            find_winner:
            mov edi , 0
            find_winner_loop:
                mov eax, edi 
                imul eax, 24
                mov ebx , dword [drone_data_array]
                add eax, ebx
                cmp dword [eax+20], 1               ; we ant to find the only active drone in array 
                je print_winner
                inc edi
                jmp find_winner_loop

                print_winner:
                    inc edi
                    push dword edi
                    push dword format_winner
                    call printf
                    add esp, 4
                    call end_co_routine


            check_R_condition:
                mov eax, dword [counter_loop]                                   
                mov ebx, dword [number_of_drones]               ; do i/N counter_loop / number of drones 
                cdq
                idiv ebx 
                mov ecx,dword [sch_cycle]
                cdq
                idiv ecx           ; eax holds the i / number of drones  and we calc eax mod R = sch_cycle
                cmp edx, 0
                jne continue_loop
                mov edi , 0
                eliminate_drone_loop:
                    cmp edi , dword [number_of_drones]
                    je end_eliminate_drone_loop
                    mov eax, edi 
                    imul eax, 24
                    mov ebx , dword [drone_data_array]
                    add eax, ebx
                    cmp dword [eax+20], 1  
                    je check_how_many_targets
                    inc edi
                    jmp eliminate_drone_loop

                    check_how_many_targets:
                        mov ecx, dword [drone_min_target]
                        cmp ecx, dword [eax+16]
                        jg switch_the_drone_with_min_target
                        inc edi
                        jmp eliminate_drone_loop

                        switch_the_drone_with_min_target:
                            mov esi, dword [eax+16]
                            mov dword [drone_min_target],esi           ; save the min target of drone 
                            mov dword [drone_min_target_index], edi         ; save the drone index with the min target 
                            inc edi 
                            jmp eliminate_drone_loop

                end_eliminate_drone_loop:
                        mov eax, dword [drone_min_target_index]
                        imul eax, 24
                        mov ebx , dword [drone_data_array]
                        add eax, ebx 
                        mov dword [eax+20], 0                           ; we elimintate the drone and change his active flag to 0 
                        dec dword [number_of_active_drones]
                        mov dword[drone_min_target], 32768               ; for next elimination
                        jmp continue_loop

                    

Resume:
    pushf
    pusha
    mov     dword edx, [Curr]        
    mov     dword [edx + 4], esp            ; save current esp
    
    do_resume:
        mov    esp, dword [ebx + 4]
        mov     dword [Curr], ebx               ; Curr points to the struct of the current co-routine
        popa
        popf
        ret     








                









