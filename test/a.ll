define i64 @julia_J_hypot_0_202(i64 zeroext %0, i64 zeroext %1) #0 {
top:
;  @ none:8 within `J_hypot_0'
; ┌ @ none within `Py_CallFunction'
   %2 = call i64 @j_Py_CallFunction_204({ [12 x i64], i64, i64, i64, i64, i64, i64, [1 x i64], [1 x i64] }* nocapture readonly @_j_const1, i64 zeroext 2337733948256, i64 zeroext %0, i64 zeroext 140726383092032) #0
; └
  %.not = icmp eq i64 %2, 0
  br i1 %.not, label %L624, label %L8

L8:                                               ; preds = %top
;  @ none:10 within `J_hypot_0'
; ┌ @ none within `Py_CallFunction'
   %3 = call i64 @j_Py_CallFunction_205({ [12 x i64], i64, i64, i64, i64, i64, i64, [1 x i64], [1 x i64] }* nocapture readonly @_j_const1, i64 zeroext 140726383032784, i64 zeroext %2) #0
; └
  %.not150 = icmp eq i64 %3, 0
  br i1 %.not150, label %L542, label %L12

L12:                                              ; preds = %L8
;  @ none:11 within `J_hypot_0'
  %.not151 = icmp eq i64 %3, 140726383032424
;  @ none within `J_hypot_0'
  %4 = inttoptr i64 %2 to i64*
  %5 = load i64, i64* %4, align 1
  %.not152 = icmp eq i64 %5, 1
;  @ none:11 within `J_hypot_0'
  br i1 %.not151, label %L15, label %L285

L15:                                              ; preds = %L12
;  @ none:29 within `J_hypot_0'
; ┌ @ C:\Users\twshe\Desktop\github\dio\src\support.jl:11 within `DIO_DecRef'
; │┌ @ C:\Users\twshe\Desktop\github\dio\src\static.jl:18 within `Py_DECREF'
    br i1 %.not152, label %L22, label %L32

L22:                                              ; preds = %L15
; │└
; │┌ @ C:\Users\twshe\Desktop\github\dio\src\static.jl:19 within `Py_DECREF'
; ││┌ @ pointer.jl:118 within `unsafe_store!' @ pointer.jl:118
     store i64 0, i64* %4, align 1
; │└└
; │┌ @ C:\Users\twshe\Desktop\github\dio\src\static.jl:20 within `Py_DECREF'
; ││┌ @ C:\Users\twshe\Desktop\github\dio\src\utils.jl:34 within `fieldptr'
; │││┌ @ C:\Users\twshe\Desktop\github\dio\src\utils.jl:34 within `macro expansion'
; ││││┌ @ int.jl:87 within `+'
       %6 = add i64 %2, 56
; │└└└└
; │┌ @ C:\Users\twshe\Desktop\github\dio\src\static.jl:21 within `Py_DECREF'
; ││┌ @ pointer.jl:105 within `unsafe_load' @ pointer.jl:105
     %7 = inttoptr i64 %6 to i64*
     %8 = load i64, i64* %7, align 1
; ││└
    %.not153 = icmp eq i64 %8, 0
    br i1 %.not153, label %fail17, label %pass18

L32:                                              ; preds = %L15
; │└
; │┌ @ C:\Users\twshe\Desktop\github\dio\src\static.jl:23 within `Py_DECREF'
; ││┌ @ int.jl:86 within `-'
     %9 = add i64 %5, -1
; ││└
; ││┌ @ pointer.jl:118 within `unsafe_store!' @ pointer.jl:118
     store i64 %9, i64* %4, align 1
     br label %L36

L36:                                              ; preds = %pass18, %L32
; └└└
;  @ none:30 within `J_hypot_0'
; ┌ @ none within `Py_CallFunction'
   %10 = call i64 @j_Py_CallFunction_206({ [12 x i64], i64, i64, i64, i64, i64, i64, [1 x i64], [1 x i64] }* nocapture readonly @_j_const1, i64 zeroext 140726383079376, i64 zeroext %0) #0
; └
  %.not154 = icmp eq i64 %10, 0
  br i1 %.not154, label %L542, label %L40

L40:                                              ; preds = %L36
;  @ none:34 within `J_hypot_0'
; ┌ @ C:\Users\twshe\Desktop\github\dio\src\support.jl:11 within `DIO_DecRef'
; │┌ @ C:\Users\twshe\Desktop\github\dio\src\static.jl:17 within `Py_DECREF'
; ││┌ @ pointer.jl:105 within `unsafe_load' @ pointer.jl:105
     %11 = inttoptr i64 %0 to i64*
     %12 = load i64, i64* %11, align 1
; │└└
; │┌ @ C:\Users\twshe\Desktop\github\dio\src\static.jl:18 within `Py_DECREF'
; ││┌ @ promotion.jl:409 within `=='
     %.not155 = icmp eq i64 %12, 1
; ││└
    br i1 %.not155, label %L47, label %L57

L47:                                              ; preds = %L40
; │└
