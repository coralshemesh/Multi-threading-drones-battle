section .data 

    cor_X: dd 0 
    cor_Y: dd 0 
    drone_angle: dd 0 
    drone_speed: dd 0
    drone_num_target_destroyed: dd 0 
    is_active: dd 1 
    delta_alpha: dd 0.0
    delta_speed: dd 0.0  
    curr_alpha: dd 0.0
    curr_speed: dd 0.0
    tmp: dd 0            ; gb variable for operations

section .text   
    global run_drone
    extern calculate_random_number
    extern random_number
    extern drone_data_array
    extern curr_drone_index
    extern number_of_drones
    extern target_co
    extern sch_co
    extern can_destroy 
    extern curr_drone_co
    extern Curr
    extern may_destroy
    extern Resume
    extern printf

    
 run_drone:
;******************calculate drone_angle******************
    finit
    call calculate_random_number
    fild dword [random_number]          ; st(0) = random_number as float point, fild convert int to float
    mov dword [random_number], 120      ; scale from [-60, 60] in total 120 
    fimul dword [random_number]         ; st(0)* 120    
    mov dword [random_number], 65535    ; div random number in MAX_INT
    fidiv dword [random_number]         ; st(0) = random_number* 120 / 65535
    fldpi                                ; push pi into the float stack  
    fmul                                 ; according to the formula deg* pi / 180 
    mov dword [random_number], 180 
    fidiv dword [random_number]    
    fstp dword [delta_alpha]            ; store st(0) in delta_alpha

 ;**********************calculate new drone position*****************   
    mov dword ebx, [drone_data_array]
    mov dword eax,  [curr_drone_index]
    imul eax, 24                        ; each drone_data is 24 bytes so we want the data in 16*cur_drone_index
    add ebx, eax                        ; curr_drone_data is located drone_data_array + curr_drone_index *20
;***************************calc new X************************** 
    mov ecx , dword [ebx+8]
    mov dword [curr_alpha], ecx              ; get alpha data of curr_drone

    fld  dword [curr_alpha]            ; push curr_alpha as float point to float stack FPU
    fcos 

    mov ecx , dword [ebx+12]
    mov dword [curr_speed], ecx             ; get speed data of curr_drone

    fld dword [curr_speed]                         ; push speed to FPU stack 
    fmul  

    mov ecx, dword[ebx]
    mov dword [cor_X], ecx

    fld dword [cor_X] 
    fadd 

    mov dword [tmp], 100                    ; check if new x is greater then 100
    fild dword [tmp]   
    fcomip    
    jb change_X_cycle_higher

    mov dword [tmp], 0                       ; check if new x is smaleer then 0 
    fild dword [tmp]   
    fcomip    
    ja change_X_cycle_lower 
    jmp end_calc_X                          ;jmp if 0<=X<=100
    change_X_cycle_higher:
        mov dword [tmp], 100
        fild dword [tmp]   
        fsub
        fabs
        jmp end_calc_X
    change_X_cycle_lower:
        mov dword [tmp], 100
        fild dword [tmp]  
        fadd 
    end_calc_X:
        fstp dword [ebx]                        ; enter the drone_date the new X calculated 
;***************************calc new Y**************************  
    mov ecx , dword [ebx+8]
    mov dword [curr_alpha], ecx              ; get alpha data of curr_drone
    
    fld  dword [curr_alpha]            ; push curr_alpha as float point to float stack FPU
    fsin 

    mov ecx , dword [ebx+12]
    mov dword [curr_speed], ecx             ; get speed data of curr_drone
    fld dword [curr_speed]                         ; push speed to FPU stack 
    fmul 

    mov ecx, dword[ebx+4]
    mov dword [cor_Y], ecx

    fld dword [cor_Y]  
    fadd 

    mov dword [tmp], 100                    ; check if new y is greater then 100
    fild dword [tmp]   
    fcomip    
    jb change_Y_cycle_higher

    mov dword [tmp], 0                       ; check if new y is smaleer then 0 
    fild dword [tmp]   
    fcomip    
    ja change_Y_cycle_lower 

    jmp end_calc_Y                           ; jmp if 0<=Y<=100
    change_Y_cycle_higher:
        mov dword [tmp], 100
        fild dword [tmp]   
        fsub 
        fabs                       
        jmp end_calc_Y
    change_Y_cycle_lower:
        mov dword [tmp], 100
        fild dword [tmp]  
        fadd                                 ; if doesnt work change to fsub and then fabs
    end_calc_Y:
        fstp dword [ebx+4]                        ; enter the drone_date the new Y calculated 
;*************************set new angle*********************************
   
    fld dword [delta_alpha]                    
    mov ecx , dword [ebx+8]
    mov dword [curr_alpha], ecx         ; get alpha data of curr_drone
    fld dword [curr_alpha]              ; push curr_alpha as float point to float stack FPU
    fadd                                 ; add delta_alpha(st(1) to curr_alpha (st(0)) in st(0)
    fldpi                               ; push pi 
    mov dword [tmp], 2                  
    fild dword [tmp]
    fmul 
    fcomip
    jb sub_alpha                        ; in st(0) we have pi and in st(1) we have the alpha after add, now we cmp if 2*pi is smaller than alpha if so CF flag is on and we jmp to sub alpha 
    mov dword [tmp], 0
    fild dword [tmp]
    fcomip 
    ja add_alpha
    jmp end_angle_calc                  ;jmp if 0 <= new alpha <= 100
    sub_alpha:
        fldpi                               ; push pi 
        mov dword [tmp], 2
        fild dword [tmp]
        fmul
        fsub
        fabs                       ; alpha is bigger than 360 so we do alpha - 360 
        jmp end_angle_calc
    
    add_alpha:
        fldpi                               ; push pi 
        mov dword [tmp], 2
        fild dword [tmp]
        fmul
        fadd                                   ; alpha is smaller than 0 so we add 360

    end_angle_calc:
        fstp dword [ebx +8]                          

;***********************calcute and set speed*************
    call calculate_random_number
    fild dword [random_number]          ; st(0) = random_number as float point, fild convert int to float
    mov dword [random_number], 20      ; scale from [-10, 10] in total 20 
    fimul dword [random_number]         ; st(0)* 20    
    mov dword [random_number], 65535    ; div random number in MAX_INT
    fidiv dword [random_number]         ; st(0) = random_number* 20 / 65535
    fst dword [delta_speed]            ; store st(0) in delta_speed
       
    mov ecx , dword [ebx+12]
    mov dword [curr_speed], ecx             ; get speed data of curr_drone

    fld dword[curr_speed]
    fadd

    mov dword [tmp], 100
    fild dword [tmp]
    fcomip 
    jb speed_is_greater_then_100                ;jmp if tmp is below curr_speed + delta_speed

    mov dword [tmp], 0
    fild dword [tmp]
    fcomip
    ja speed_is_lower_then_0                    ;jmp if tmp is above new speed

    jmp end_speed_calc                          ;jmp if 0<= new speed <= 100

    speed_is_greater_then_100:
        fstp dword [tmp]
        mov dword [tmp], 100
        fild dword [tmp]
        jmp end_speed_calc
    
    speed_is_lower_then_0:
        fstp dword [tmp]
        mov dword [tmp], 0
        fild dword [tmp]

    end_speed_calc:
        fstp dword [ebx+12]                         

;***********************trying to destroy the target********************

    call may_destroy
    cmp dword [can_destroy] , 0 
    je cant_destroy

    can_destroy_lable:
        mov ecx, dword[ebx+16]
        inc ecx
        mov dword[ebx+16], ecx                           ;insert num of target of cuur drone to data array
        mov esi, dword [curr_drone_co]
        mov dword [Curr], esi

        mov     dword ebx, target_co
        call    Resume
        jmp     run_drone

    cant_destroy:
        mov esi, dword [curr_drone_co]
        mov dword [Curr], esi

        mov     dword ebx, sch_co
        call    Resume
        jmp     run_drone 


    





