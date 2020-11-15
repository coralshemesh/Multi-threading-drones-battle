
section .data 
    extern calculate_random_number
    extern random_number
    extern drones_array
    extern curr_drone_index
    extern number_of_drones
    extern drone_data_array
    extern target_co
    extern sch_co
    extern max_distance 
    global x_target
    global y_target
    extern curr_drone_co
    extern drone_num_target_destroyed
    global can_destroy
    extern Curr
    x_target: dd 0.0
    y_target: dd 0.0
    x_drone: dd 0.0
    y_drone: dd 0.0
    delta_y: dd 0.0
    delta_x: dd 0.0
    distance_drone_to_target: dd 0.0
    can_destroy: dd 0

section .text   
    global run_target
    global may_destroy
    global create_target
    extern Resume
    extern printf


run_target:

    finit
    call create_target

    mov dword esi, target_co  
    mov dword [Curr], esi

    mov dword ebx , [curr_drone_co]
    call Resume 
    jmp run_target

create_target:
;*******************calculate X random value for target position*************************
    call calculate_random_number
    fild dword [random_number]          ; st(0) = random_number as float point, fild convert int to float
    mov dword [random_number], 100      ; scale from [0, 100] in total 100 
    fimul dword [random_number]         ; st(0)* 100    
    mov dword [random_number], 65535    ; div random number in MAX_INT
    fidiv dword [random_number]         ; st(0) = random_number* 100 / 65535
    fstp dword [x_target]               ; store st(0) in delta_alpha

;************************calculate Y random value for target position**************************
    call calculate_random_number
    fild dword [random_number]          ; st(0) = random_number as float point, fild convert int to float
    mov dword [random_number], 100      ; scale from [0, 100] in total 100 
    fimul dword [random_number]         ; st(0)* 100    
    mov dword [random_number], 65535    ; div random number in MAX_INT
    fidiv dword [random_number]         ; st(0) = random_number* 100 / 65535
    fstp dword [y_target]            ; store st(0) in delta_alpha

    ret 


may_destroy:
;*******************************drone position*********************************
    mov  ebx,dword [drone_data_array]
    mov  eax, dword [curr_drone_index]
    imul eax, 24                        ; each drone_data is 24 bytes so we want the data in 40*cur_drone_index
    add ebx, eax                        ; curr_drone_data is located drone_data_array + curr_drone_index *20

    mov esi , dword [ebx]
    mov dword [x_drone], esi

    mov esi , dword [ebx+4]
    mov dword [y_drone], esi

;********************************calculate Delta x******************************
    fld dword [x_drone]
    fld dword [x_target]
    fsub 
    fabs
    fstp dword [delta_x]

;********************************calculate Delta y******************************
    fld dword [y_drone]
    fld dword [y_target]
    fsub 
    fabs
    fstp dword [delta_y]
    
;********************************calculate the angle between delta x and delta y***********
    fld dword[delta_x]
    fld dword[delta_x]
    fmul
    fstp dword[delta_x]

    fld dword[delta_y]
    fld dword[delta_y]
    fmul
    fstp dword[delta_y]

    fld dword[delta_x]
    fld dword[delta_y]
    fadd
    fsqrt
    fstp dword [distance_drone_to_target]

;********************************check conditions to disntande between drone to target*************
    fld dword [distance_drone_to_target]
    fild dword [max_distance]
    fcomip 
    ja  drone_can_destroy
    mov dword [can_destroy], 0
    jmp end_may_destroy

    drone_can_destroy:
        mov dword [can_destroy], 1


    end_may_destroy:
        ret



