;;; pio-mode.el --- Major mode for editing PIO assembly files -*- lexical-binding: t; -*-

;; Author: 8dcc <8dcc.git@gmail.com>
;; Version: 1.0.0
;; Package-Requires: ((emacs "24.1") (polymode "0.2.2"))
;; Keywords: languages
;; URL: https://github.com/8dcc/pio-mode.el

;; This program is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation, either version 3 of the License, or (at your option) any later
;; version.
;;
;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
;; details.
;;
;; You should have received a copy of the GNU General Public License along with
;; this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides two major modes for editing PIO assembly files.  First,
;; `pio-mode', which inherits from `asm-mode' and highlights the base assembly
;; syntax.  Second, `poly-pio-mode', built on top of the "polymode" package,
;; which adds support for the embedded C blocks.
;;
;; The Programable I/O state machines were originally developed for the RP2040
;; microcontroller by Raspberry Pi.  Through "bit-banging", they allow the
;; programmer to interact with existing or new hardware interfaces efficiently.
;;
;; See also: https://www.raspberrypi.com/news/what-is-pio/

;;; Code:

(defconst pio-directives
  '("program" "wrap_target" "wrap" "side_set" "define" "origin" "lang_opt" "fifo")
  "PIO assembler directives.")

(defconst pio-instructions
  '("jmp" "wait" "in" "out" "push" "pull" "mov" "irq" "set" "nop")
  "PIO instruction mnemonics.")

(defconst pio-jmp-conditions
  '("!x" "x--" "!y" "y--" "x!=y" "pin" "!osre")
  "PIO JMP instruction condition codes.")

(defconst pio-registers
  '("pins" "x" "y" "null" "isr" "osr" "status" "pc" "exec" "pindirs" "gpio" "rxfifo")
  "PIO registers and special source/destination identifiers.")

(defconst pio-modifiers
  '("rel" "prev" "next" "iffull" "ifempty" "block" "noblock"
    "set" "wait" "nowait" "clear" "side" "opt" "public")
  "PIO instruction and directive modifiers.")

(defvar pio-font-lock-keywords
  (list
   ;; Directives (must start with a dot)
   (cons (rx line-start "." (regexp (regexp-opt pio-directives)) word-boundary)
         'font-lock-preprocessor-face)

   ;; C block delimiters
   (cons (rx (or (seq line-start "%" (* space) "c-sdk" (* space) "{")
                 (seq line-start "%}")))
         'font-lock-preprocessor-face)

   ;; Instructions
   (cons (rx word-boundary (regexp (regexp-opt pio-instructions)) word-boundary)
         'font-lock-keyword-face)

   ;; JMP conditions (handle special characters properly)
   (cons (rx word-boundary (regexp (regexp-opt pio-jmp-conditions)) word-boundary)
         'font-lock-builtin-face)

   ;; Registers and special sources/destinations
   (cons (rx word-boundary (regexp (regexp-opt pio-registers)) word-boundary)
         'font-lock-variable-name-face)

   ;; Modifiers
   (cons (rx word-boundary (regexp (regexp-opt pio-modifiers)) word-boundary)
         'font-lock-builtin-face)

   ;; MOV operations (bitwise NOT and bit-reverse)
   '("::\\|[!~]" . font-lock-builtin-face)

   ;; Numeric literals
   (cons (rx word-boundary "0" (or "x" "X") (+ hex-digit)) 'font-lock-constant-face)
   (cons (rx word-boundary "0" (or "b" "B") (+ (any "01"))) 'font-lock-constant-face)
   (cons (rx word-boundary (+ digit)) 'font-lock-constant-face)

   ;; Labels (word followed by colon)
   (list (rx line-start (* space)
             (group (seq (any "a-z" "A-Z" "_")
                         (* (any "a-z" "A-Z" "0-9" "_"))))
             ":")
         1 'font-lock-function-name-face)

   ;; Square brackets for array indexing (rxfifo[y])
   (list (rx "[" (group (+ (not (any "]")))) "]")
         1 'font-lock-variable-name-face))
  "Syntax highlighting rules for PIO assembly.")

(define-derived-mode pio-mode asm-mode "PioASM"
  "Major mode for PIO assembly files.

The Programable I/O state machines were originally developed for the RP2040
microcontroller by Raspberry Pi.  Through \"bit-banging\", they allow the
programmer to interact with existing or new hardware interfaces efficiently."
  (setq-local comment-start "; ")
  (setq-local comment-end "")
  (setq-local comment-start-skip ";+\\s-*")
  (setq font-lock-defaults '(pio-font-lock-keywords)))

;; -----------------------------------------------------------------------------

(define-hostmode poly-pio-hostmode
  :mode 'pio-mode)

(define-innermode poly-pio-c-innermode
  :mode 'c-mode
  :head-matcher "^% c-sdk {$"
  :tail-matcher "^%}$"
  :head-mode 'host
  :tail-mode 'host)

(define-polymode poly-pio-mode
  :hostmode 'poly-pio-hostmode
  :innermodes '(poly-pio-c-innermode))

(add-to-list 'auto-mode-alist
             '("\\.pio$" . poly-pio-mode))

(provide 'pio-mode)

;;; pio-mode.el ends here
