#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

;  ! == Alt
;  ^ == Ctrl
;  + == Shift

!r::
Send, {F2}
return

!c::
Send, {Ctrl down}{c down}{c up}{Ctrl up}
return

!v::
Send, {Ctrl down}{v down}{v up}{Ctrl up}
return

!a::
Send, {Ctrl down}{a down}{a up}{Ctrl up}
return

!p::
Send, {Ctrl down}{p down}{p up}{Ctrl up}
return

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; ~~~~~~~~~~~~    ARROW KEYS    ~~~~~~~~~~~~~~~~~~~
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!j::
Send, {Left down}{Left up}
return

!k::
Send, {Down down}{Down up}
return

!l::
Send, {Right down}{Right up}
return

!i::
Send, {Up down}{Up up}
return

!h::
Send, {PgUp down}{PgUp up}
return

!n::
Send, {PgDn down}{PgDn up}
return

^j::
Send, {Ctrl down}{Left down}{Left up}{Ctrl up}
return

^k::
Send, {Down down}{Down up}{Down down}{Down up}{Down down}{Down up}{Down down}{Down up}{Down down}{Down up}{Down down}{Down up}
return

^l::
Send, {Ctrl down}{Right down}{Right up}{Ctrl up}
return

^i::
Send, {Up down}{Up up}{Up down}{Up up}{Up down}{Up up}{Up down}{Up up}{Up down}{Up up}{Up down}{Up up}
return

!^j::
Send, {Left down}{Left up}
return

!^k::
Send, {Down down}{Down up}
return

!^l::
Send, {Right down}{Right up}
return

!^i::
Send, {Up down}{Up up}
return

!+j::
Send {Shift down}{Left down}{Left up}{Shift up}
return

!+k::
Send {Shift down}{Down down}{Down up}{Shift up}
return

!+l::
Send {Shift down}{Right down}{Right up}{Shift up}
return

!+i::
Send {Shift down}{Up down}{Up up}{Shift up}
return

^+j::
Send {Ctrl down}{Shift down}{Left down}{Left up}{Shift up}{Ctrl up}
return

^+k::
Send {Ctrl down}{Shift down}{Down down}{Down up}{Shift up}{Ctrl up}
return

^+l::
Send {Ctrl down}{Shift down}{Right down}{Right up}{Shift up}{Ctrl up}
return

^+i::
Send {Ctrl down}{Shift down}{Up down}{Up up}{Shift up}{Ctrl up}
return

^+!j::
Send {Ctrl down}{Shift down}{Left down}{Left up}{Shift up}{Ctrl up}
return

^+!k::
Send {Ctrl down}{Shift down}{Down down}{Down up}{Shift up}{Ctrl up}
return

^+!l::
Send {Ctrl down}{Shift down}{Right down}{Right up}{Shift up}{Ctrl up}
return

^+!i::
Send {Ctrl down}{Shift down}{Up down}{Up up}{Shift up}{Ctrl up}
return

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~




; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; ~~~~~~~~~~~~~~~    HOME    ~~~~~~~~~~~~~~~~~~~~~~
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!u::
Send, {Home down}{Home up}
return

^u::
Send, {Home down}{Home up}
return

^!u::
Send, {Home down}{Home up}
return

!+u::
Send {Shift down}{Home down}{Home up}{Shift up}
return
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; ~~~~~~~~~~~~~~~    END    ~~~~~~~~~~~~~~~~~~~~~~~
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!o::
Send, {End down}{End up}
return

^o::
Send, {End down}{End up}
return

^!o::
Send, {End down}{End up}
return

!+o::
Send, {Shift down}{End down}{End up}{Shift up}
return
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; ~~~~~~~~~~~    COMMENT UTIL KEYS    ~~~~~~~~~~~~~
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;+Space::
;Send, {Ctrl down}{/ down}{/ up}{Ctrl up}
;return

;^Space::
;Send, {Ctrl down}{BackSpace down}{BackSpace up}{Ctrl up}
;return



;!g::
;Send, {Ctrl down}{m down}{m up}{Ctrl up}
;return

;^g::
;Send, {Ctrl down}{m down}{m up}{Ctrl up}
;return

;^!g::
;Send, {Ctrl down}{m down}{m up}{Ctrl up}
;return

;!+g::
;Send, {Ctrl down}{m down}{m up}{Ctrl up}
;return

;^!Space::
;Send, {Ctrl down}{, down}{, up}{Ctrl up}
;return

;!+Space::
;Send, {Ctrl down}{, down}{, up}{Ctrl up}
;return
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; ~~~~~~~~~~~~~~~    MOUSE BUTTONS    ~~~~~~~~~~~~~
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

;XButton1::
;Send, {BackSpace}
;return

;XButton2::
;Send, {Enter}
;return

;^5::
;Send, {BackSpace down}{BackSpace up}
;return


; CTRL KEYS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

;!h::
;Send, {Ctrl down}{Left down}{Left up}{Ctrl up}
;return

;!;::
;Send, {Ctrl down}{Right down}{Right up}{Ctrl up}
;return

;!c::
;Send, {Ctrl down}{c down}{c up}{Ctrl up}
;return

;!v::
;Send, {Ctrl down}{v down}{v up}{Ctrl up}
;return

;!x::
;Send, {Ctrl down}{x down}{x up}{Ctrl up}
;return

;!z::
;Send, {Ctrl down}{z down}{z up}{Ctrl up}
;return

;!f::
;Send, {Ctrl down}{f down}{f up}{Ctrl up}
;return

;!n::
;Click, WheelDown
;return

;!p::
;Click, WheelUp
;return

; VISUAL STUDIO BINDS ~~~~~~~~~~~~~~~~~~~~~~~

;!+p::
;Send, {Ctrl down} {Shift down} {t down} {t up} {Shift up} {Ctrl up}
;return



