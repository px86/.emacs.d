(defconst my-gnu/linux-laptop-p
  (and (equal system-type 'gnu/linux)
       (eq (string-search "android" system-configuration) nil))
  "If the value is t, emacs is running on my gnu/linux laptop.")

(defconst my-android-phone-p
  (not (eq (string-search "android" system-configuration) nil))
  "If the value is t, emacs is running inside termux, on my android phone.")

(defconst my-windows-laptop-p
  (equal system-type 'windows-nt)
  "If the value is t, emacs is running on my windows laptop.")

(setq gc-cons-threshold (* 64 1000000))

(when (native-comp-available-p)
  (setq native-comp-async-report-warnings-errors nil)
  ;; (setq native-comp-async-report-warnings-errors 'silent)
  (add-to-list 'native-comp-eln-load-path
               (expand-file-name "eln-cache/"
                                 user-emacs-directory)))

(fset 'yes-or-no-p 'y-or-n-p)

(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)

(setq echo-keystrokes 0.01)

(menu-bar-mode -1)
(column-number-mode)

(unless my-android-phone-p
  (tool-bar-mode -1)
  (tooltip-mode -1)
  (set-fringe-mode 10)
  (scroll-bar-mode -1))

(setq inhibit-startup-screen t
      scroll-conservatively 101)

;; prevent the annoying bell sounds
(setq visible-bell t)

(setq initial-major-mode 'fundamental-mode)
(setq initial-scratch-message "")

(defvar my-buffers-to-bury (list "*dashboard*" "*scratch*")
  "Bury these buffers instead of killing them.")

(defun my-kill-current-buffer ()
  "Kill current buffer immediately, if it is not present in `my-buffers-to-bury'."
  (interactive)
  (if (member (buffer-name) my-buffers-to-bury)
      (bury-buffer)
    (kill-buffer (current-buffer))))

(global-set-key (kbd "C-x k") 'my-kill-current-buffer)

(when my-gnu/linux-laptop-p
  (set-frame-parameter (selected-frame) 'alpha-background 90)
  (add-to-list 'default-frame-alist `(alpha-background . 90)))

  ;; (when my-gnu/linux-laptop-p
  ;;   (set-frame-parameter (selected-frame) 'alpha-background 100)
  ;;   (add-to-list 'default-frame-alist `(alpha-background . 100)))

(add-to-list 'default-frame-alist '(fullscreen . maximized))

(defvar my-monospace-fonts
  '("Monaspace Radon Var" "Cascadia Code" "JetBrains Mono" "Consolas")
  "A list of preferred monospace fonts, arranged from most favoured to least favoured.")

(defvar my-sans-serif-fonts
  '("Andika" "Lato" "Noto sans" "Open sans")
  "A list of preferred sans-serif fonts, arranged from most favoured to least favoured.")

(defun my-select-first-available-font (fonts &optional default)
  "Select first available font from a list of fonts."
  (if-let ((font (car fonts)))
      (if (find-font (font-spec :family font))
          font
        (my-select-first-available-font (cdr fonts)))
    default))

(defun my-set-font-faces ()
  "Set font faces."
  (set-face-attribute 'default nil
                      :family (my-select-first-available-font my-monospace-fonts "monospace")
                      :weight 'normal
                      :height 108)

  (set-face-attribute 'fixed-pitch nil
                      :family (face-attribute 'default :family)
                      :weight 'normal
                      :height 1.0)

  (set-face-attribute 'variable-pitch  nil
                      :family (my-select-first-available-font my-sans-serif-fonts "sans-serif")
                      :height 1.0))

(my-set-font-faces)
(add-hook 'server-after-make-frame-hook
          (lambda ()
            (my-set-font-faces)))

(global-set-key (kbd "M-SPC")
                (lambda ()
                  "Instruct `cycle-spacing' to delete newlines too."
                  (interactive)
                  (cycle-spacing -1)))

(add-hook 'before-save-hook
          'delete-trailing-whitespace)

(defun my-set-register-if-file-exists (key filename)
  "Set the register with given KEY if FILENAME exists."
  (if (file-exists-p filename)
      (set-register key `(file . ,filename))))

(my-set-register-if-file-exists ?E
      			  (concat (file-name-as-directory user-emacs-directory)
      				  "config.org"))
(cond
 (my-gnu/linux-laptop-p
  (my-set-register-if-file-exists ?B "~/.local/data/bookmarks")
  (my-set-register-if-file-exists ?H "~/.config/hypr/hyland.conf")
  (my-set-register-if-file-exists ?K "~/.config/hypr/keybindings.conf")
  (my-set-register-if-file-exists ?W "~/.config/waybar/config")
  (my-set-register-if-file-exists ?G "~/src/repos/px86/README.org"))
 (my-windows-laptop-p
  (my-set-register-if-file-exists ?B "~/bookmarks.txt")))

(global-unset-key (kbd "C-z"))

(require 'package)

(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("org" . "https://orgmode.org/elpa/")
                         ("elpa" . "https://elpa.gnu.org/packages/")))

(package-initialize)
(unless package-archive-contents (package-refresh-contents))

(when (< emacs-major-version 29)
  (unless (package-installed-p 'use-package)
    (package-install 'use-package)))

(require 'use-package)
(setq use-package-always-ensure t)
(setq use-package-verbose t)

(use-package no-littering)

(setq auto-save-file-name-transforms
      `((".*" ,(no-littering-expand-var-file-name "auto-save/") t)))

(setq backup-directory-alist
      `(("." . ,(no-littering-expand-var-file-name "backup/"))))

;; prevent Emacs form littering into init.el
(setq custom-file (no-littering-expand-etc-file-name "custom.el"))

(use-package all-the-icons
  :if (display-graphic-p)
  :config
  (setq all-the-icons-scale-factor 1.25))

(use-package nerd-icons
  :config
  (setq nerd-icons-scale-factor 1.25))

(use-package ef-themes
  :ensure t
  :config
  (setq ef-themes-to-toggle '(ef-arbutus ef-dark)))

(use-package doom-themes
  :ensure t
  :config
  (setq doom-themes-enable-bold t)
  (setq doom-themes-enable-italic t))

(defun my-disable-all-loaded-themes ()
  "Disable all loaded themes."
  (interactive)
  (dolist (theme custom-enabled-themes)
    (message "Disabling `%s' theme" theme)
    (disable-theme theme)))

;; Note: the following is used in external script
(defun my-load-theme (theme)
  "Load given theme after disabling all loaded themes."
  (my-disable-all-loaded-themes)
  (load-theme theme t nil)
  ;; FIXME: find a better way to override the modeline color
  (let ((bg-color (face-attribute 'default :background)))
    (set-face-attribute 'mode-line nil
                        :background bg-color)
    (set-face-attribute 'mode-line-inactive nil
                        :background bg-color)))

(my-load-theme 'doom-ir-black)

(use-package doom-modeline
  :ensure t
  :config
  (setq doom-modeline-icon t)
  (setq doom-modeline-height 16)
  (setq doom-modeline-bar-width 0)
  (doom-modeline-mode 1))

(use-package dashboard
  :config
  (dashboard-setup-startup-hook)
  (if my-windows-laptop-p
      (fset #'dashboard-replace-displayable (lambda (arg &rest _) arg)))
  :init
  (setq dashboard-startup-banner
        (let ((logo-file (expand-file-name "logo.xpm" user-emacs-directory)))
          (if (file-exists-p logo-file)
              logo-file
            'logo)))
  (setq dashboard-image-banner-max-height 200)
  (setq dashboard-image-banner-max-width  200)
  (setq dashboard-center-content t)
  (setq dashboard-set-heading-icons t)
  (setq dashboard-icon-type 'nerd-icons)
  (setq dashboard-set-file-icons t)
  (setq dashboard-set-init-info t)
  (setq dashboard-projects-backend 'project-el)
  (setq dashboard-items '((recents  . 5)
                          (projects . 5)
                          ;; (agenda . 3)
                          (registers . 5))))

(use-package savehist
  :config
  (setq history-length 25)
  (savehist-mode 1))

(use-package vertico
  :config
  (setq vertico-cycle t)
  (setq vertico-resize t)
  (vertico-mode)
  (vertico-reverse-mode))

(use-package orderless
  :init
  (setq completion-styles '(orderless)
        completion-category-defaults nil
        completion-category-overrides
        '((file (styles . (partial-completion))))))

(use-package marginalia
  :after vertico
  :config
  (setq marginalia-align 'right)
  (setq marginalia-annotators '(marginalia-annotators-heavy
                                marginalia-annotators-light nil))
  (marginalia-mode))

(use-package ace-window
  :ensure t
  :bind ("M-o" . ace-window)
  :config
  (setq aw-keys '(?h ?j ?k ?l ?y ?u ?i ?o ?p))
  (setq aw-display-mode-overlay t)
  (setq aw-background t)
  (setq aw-dispatch-always t)
  (setq aw-minibuffer-flag t)
  (setq aw-dispatch-alist
        '((?s aw-swap-window "Swap Windows")
          (?0 aw-delete-window "Delete Window")
          (?2 aw-split-window-vert "Split Vert Window")
          (?3 aw-split-window-horz "Split Horz Window")
          (?b aw-switch-buffer-in-window "Select Buffer")
          (?? aw-show-dispatch-help "Show Dispatch Help"))))

(winner-mode)

(setq split-height-threshold nil)
(setq split-width-threshold 145)

(setq display-buffer-alist
      `(((derived-mode . compilation-mode)
         (display-buffer-reuse-window display-buffer-below-selected)
         (dedicated . t)
         (preserve-size (nil . t))
         (window-height . fit-window-to-buffer))

        ;; ;; no window
        ;; ("\\`\\*Async Shell Command\\*\\'"
        ;;  (display-buffer-no-window))
        ("\\`\\*\\(Warnings\\|Compile-Log\\|Org Links\\)\\*\\'"
         (display-buffer-no-window)
         (allow-no-window . t))

        ;; bottom side window
        ;; the `org-capture' key selection and `org-add-log-note'
        ("\\*\\(Org \\(Select\\|Note\\)\\|Agenda Commands\\)\\*"
         (display-buffer-in-side-window)
         (dedicated . t)
         (side . bottom)
         (slot . 0)
         (window-parameters . ((mode-line-format . none))))

        ;; bottom buffer (NOT side window)
        ((or . ((derived-mode . flymake-diagnostics-buffer-mode)
                (derived-mode . flymake-project-diagnostics-mode)
                (derived-mode . messages-buffer-mode)
                (derived-mode . backtrace-mode)))
         (display-buffer-reuse-mode-window display-buffer-at-bottom)
         (window-height . 0.3)
         (dedicated . t)
         (preserve-size . (t . t)))

        ("\\*\\(Output\\|Register Preview\\).*"
         (display-buffer-reuse-mode-window display-buffer-at-bottom))

        ;; below current window
        ("\\(\\*Capture\\*\\|CAPTURE-.*\\)"
         (display-buffer-reuse-mode-window display-buffer-below-selected))

        ((derived-mode . reb-mode) ; M-x re-builder
         (display-buffer-reuse-mode-window display-buffer-below-selected)
         (window-height . 4) ; note this is literal lines, not relative
         (dedicated . t)
         (preserve-size . (t . t)))

        ("\\*\\(Calendar\\|Bookmark Annotation\\|ert\\).*"
         (display-buffer-reuse-mode-window display-buffer-below-selected)
         (dedicated . t)
         (window-height . fit-window-to-buffer))))

(setq-default window-divider-default-places t)
(setq-default window-divider-default-bottom-width 2)
(setq-default window-divider-default-right-width 2)
(window-divider-mode t)
(set-face-attribute 'window-divider nil
                    :foreground "#BE56D6")
                    ;; :foreground "#b16e75")

(defun my-org-font-face-setup ()
  "Set necessary font faces in `org-mode'."

  (dolist (face '((org-level-1 . 1.25)
                  (org-level-2 . 1.15)
                  (org-level-3 . 1.05)
                  (org-level-4 . 1.0)
                  (org-level-5 . 1.0)
                  (org-level-6 . 1.0)
                  (org-level-7 . 1.0)
                  (org-level-8 . 1.0)))
    (set-face-attribute (car face) nil
                        :height (cdr face)
                        :weight 'bold))

  ;; fixed-pitch face setup
  (dolist (face '(org-table
                  org-formula org-block
                  org-code org-verbatim
                  org-checkbox line-number
                  org-special-keyword
                  line-number-current-line))
    (set-face-attribute face nil :inherit 'fixed-pitch))

  (dolist (face '(org-table
                  org-document-info-keyword
                  org-meta-line))
    (set-face-attribute face nil
                        :foreground 'unspecified
                        :inherit '(shadow fixed-pitch))))

(use-package org
  :pin org
  :commands
  (org-capture org-agenda org-timer-set-timer)
  :hook
  (org-mode . (lambda ()
                (my-org-font-face-setup)
                ;; (if my-gnu/linux-laptop-p (flyspell-mode))
                (org-indent-mode)
                (visual-line-mode 1)))
  :init
  (setq org-directory (cond (my-android-phone-p "~/storage/org")
                            (my-windows-laptop-p "~/org")
                            (my-gnu/linux-laptop-p "~/docs/org")
                            ("~/org")))
  :custom
  (org-ellipsis " ▾")
  (org-hide-emphasis-markers nil)
  (org-startup-folded 'overview)
  :config
  ;; (require 'org-habit)
  ;; (add-to-list 'org-modules 'org-habit)
  ;; (setq org-habit-graph-column 60)
  (advice-add 'org-refile
              :after 'org-save-all-org-buffers)

  ;; Add a clock sound for `org-timer-set-timer'
  (let ((sound-file "~/.local/data/bell.wav"))
    (if (file-exists-p sound-file)
        (setq org-clock-sound sound-file)))

  ;; org-agenda
  (setq org-agenda-files (list (expand-file-name "tasks.org" org-directory)))
  (setq org-agenda-start-with-log-mode t)
  (setq org-log-done 'time)
  (setq org-log-into-drawer t)
  (setq org-todo-keywords
        '((sequence "TODO(t)" "NEXT(n)" "PROG(p)" "INTR(i)" "WAIT(w@/!)" "|" "DONE(x!)" "NULL(k@)")))
  (setq org-todo-keyword-faces
        '(("TODO" . "royal blue")
          ("NEXT" . "sea green")
          ("PROG" . "yellow green")
          ("INTR" . "purple1")
          ("WAIT" . "violet red")))
  (setq org-enforce-todo-dependencies t)
  (setq org-track-ordered-property-with-tag t)
  (setq org-agenda-dim-blocked-tasks t)
  (setq org-priority-highest 1)
  (setq org-priority-lowest 10)
  (setq org-priority-default 5))

(global-set-key (kbd "C-c a") #'org-agenda)

(global-set-key (kbd "C-c c") #'org-capture)

(setq org-capture-templates
      `(("t" "Todo item" entry
         (file+headline "tasks.org" "Inbox")
         ,(concat "* TODO %^{Title}\n"
                  ":PROPERTIES:\n"
                  ":ID: %(org-id-uuid)\n"
                  ":CREATED: %U\n"
                  ":END:\n")
         :prepend t)

        ("u" "Urgent todo item" entry
         (file+headline "tasks.org" "Inbox")
         ,(concat "* TODO [#1] %^{Title}\n"
                  "DEADLINE: %t\n"
                  ":PROPERTIES:\n"
                  ":ID: %(org-id-uuid)\n"
                  ":CREATED: %U\n"
                  ":END:\n")
         :prepend t)

        ("r" "Web article to read" entry
         (file+headline "tasks.org" "Reading list")
         ,(concat "* TODO %^{Description}\n"
                  ":PROPERTIES:\n"
                  ":ID: %(org-id-uuid)\n"
                  ":CREATED: %U\n"
                  ":TOPIC: %^{Topic}\n"
                  ":END:\n"
                  "URL: %(current-kill 0)\n"
                  "Note: %?\n")
         :empty-lines-after 1)

        ("n" "Quick note" entry
         (file+headline "tasks.org" "Notes")
         ,(concat "* %^{Title}\n"
                  ":PROPERTIES:\n"
                  ":ID: %(org-id-uuid)\n"
                  ":CREATED: %U\n"
                  ":END:\n"
                  "\n%?")
         :empty-lines-after 1)

        ("p" "New project" entry
         (file+headline "tasks.org" "Projects")
         ,(concat "* %^{Name}\n"
                  ":PROPERTIES:\n"
                  ":ID: %(org-id-uuid)\n"
                  ":CREATED: %U\n"
                  ":END:\n\n"
                  "** Objective\n%?\n"
                  "** Motivation\n"
                  "** Technologies\n"
                  "** Schedules\n"
                  "** Notes\n"
                  "** Progress [/]\n")
         :empty-lines-after 1)))

(use-package org-bullets
  :hook (org-mode . org-bullets-mode)
  :custom
  (org-bullets-bullet-list '("◉")))

(with-eval-after-load 'org
  (require 'org-tempo)
  (dolist (language '(("el" . "src emacs-lisp")
                      ("py" . "src python")
                      ("sh" . "src shell")
                      ("js" . "src js")))
    (add-to-list 'org-structure-template-alist language)))

(with-eval-after-load 'org
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((python . t)
     (emacs-lisp . t))))

(setq org-confirm-babel-evaluate nil)

(use-package org-roam
  :commands (org-roam-node-find
             org-roam-node-insert
             org-roam-dailies-capture-today
             org-roam-dailies-goto-today
             org-roam-dailies-goto-date)
  :bind (("C-c n f" . org-roam-node-find)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n l" . org-roam-buffer-toggle)
         :map org-mode-map
         ("C-M-i" . completion-at-point)
         :map org-roam-dailies-map
         ("Y" . org-roam-dailies-capture-yesterday)
         ("T" . org-roam-dailies-capture-tomorrow))
  :bind-keymap
  ("C-c n d" . org-roam-dailies-map)
  :init
  (setq org-roam-directory (expand-file-name "roam" org-directory))
  :config
  (require 'org-roam-dailies)
  (org-roam-db-autosync-enable)
  (setq org-roam-dailies-directory "dailies/")
  (setq org-roam-db-location "~/.cache/org-roam.db"))

(when my-gnu/linux-laptop-p
  (use-package vterm
    :ensure t
    :init (setq vterm-always-compile-module t)))

(use-package editorconfig
  :ensure t)

(keymap-global-set "<f5>" #'recompile)

(setq-default c-basic-offset 2)
(setq-default indent-tabs-mode nil)
(setq-default lsp-enable-indentation nil) ;; EXPERIMENTAL

(add-hook 'prog-mode-hook
          (lambda ()
            ;;(local-set-key (kbd "C-<tab>") 'yas-expand)
            ;; (set-fringe-style 8)
            (editorconfig-mode 1)
            (hl-line-mode)
            (electric-pair-local-mode)))

(use-package project
  :demand t)

(use-package magit
  :commands magit-status
  :config
  (setq magit-display-buffer-function
        #'magit-display-buffer-same-window-except-diff-v1))

(use-package company
  :commands (company-mode global-company-mode)
  :hook ((prog-mode text-mode org-mode) . company-mode)
  :bind
  (:map company-active-map
        ("<tab>" . company-complete-selection))
  :config
  (setq company-minimum-prefix-length 2)
  (setq company-idle-delay 0.2))

(use-package flycheck
  :disabled t
  :commands (global-flycheck-mode flycheck-mode)
  :hook (prog-mode . flycheck-mode))

(use-package yasnippet
  :requires warnings  ;; for `warning-suppress-types' below
  :config
  (setq yas-snippet-dirs
        `( ,(concat user-emacs-directory "snippets")))
  (add-to-list 'warning-suppress-types '(yasnippet backquote-change))
  (yas-global-mode 1)
  (yas-reload-all))

(setq treesit-extra-load-path '("~/.local/lib/"))

(use-package eglot
  ;; :disabled t
  :ensure t
  :commands eglot
  :autoload eglot-ensure
  :bind
  (:map eglot-mode-map
        ("C-c l r" . eglot-rename)
        ("C-c l =" . eglot-format))
  :config
  (fset #'jsonrpc--log-event #'ignore)
  ;; (setq eglot-events-buffer-size 0)
  (setq eglot-sync-connect nil)
  (setq eglot-connect-timeout nil)
  (setq eglot-autoshutdown t)
  (setq eglot-send-changes-idle-time 3)
  (setq eglot-ignored-server-capabilities '( :documentHighlightProvider)))

(use-package lsp-mode
  :disabled t
  :commands
  (lsp lsp-deferred)
  :hook
  ((java-mode java-ts-mode python-mode python-ts-mode go-ts-mode) . lsp)
  :init
  (setq lsp-headerline-breadcrumb-enable 'nil)
  (setq lsp-keymap-prefix "C-c l")
  :config
  (setq-default lsp-clients-clangd-args
                '("--cross-file-rename"
                  "--enable-config"
                  "--fallback-style=WebKit"
                  "--clang-tidy"
                  "--clang-tidy-checks='*'"
                  "--suggest-missing-includes"
                  "--header-insertion=iwyu"
                  "--header-insertion-decorators=0")))

(use-package lsp-ui
  :disabled t
  :after lsp-mode)

(use-package dape
  :ensure t
  :commands (dape))

(use-package multiple-cursors
  :bind
  ("C-S-c C-S-c" . mc/edit-lines)
  ("C->" . mc/mark-next-like-this)
  ("C-<" . mc/mark-previous-like-this)
  ("C-c C-<" . mc/mark-all-like-this))

(use-package web-mode
  :mode ("\\.html?$" "\\.djhtml$" "\\.mustache\\'" "\\.phtml\\'"
         "\\.as[cp]x\\'" "\\.erb\\'" "\\.hbs\\'" "\\.jsp\\'")
  :config
  (setq web-mode-markup-indent-offset 2)
  (setq web-mode-css-indent-offset 2)
  (setq web-mode-code-indent-offset 2)
  (setq web-mode-enable-html-entities-fontification t)
  (setq web-mode-enable-current-column-highlight t)
  (setq web-mode-auto-close-style 2))

(use-package emmet-mode
  :hook ((web-mode css-mode sgml-mode) . emmet-mode))

(use-package python
  :interpreter
  ("python" . python-mode)
  ("python3" . python-mode))

(use-package pyvenv
  :config
  (pyvenv-mode))

(use-package js
  :interpreter "node"
  :init
  (setq js-jsx-syntax t)
  :config
  (setq js-indent-level 2))

(use-package typescript-mode
  :disabled t
  :mode "\\.ts\\'"
  :config
  (setq typescript-indent-level 2))

(add-hook 'emacs-lisp-mode-hook
          (lambda ()
            (setq-local company-backends
                        '(company-elisp
                          company-files
                          company-yasnippet))
            (company-mode)))

(use-package lsp-java
  :disabled t
  :hook (java-mode . lsp-java))

(if (not my-windows-laptop-p)
    (use-package java-ts-mode
      :commands (java-ts-mode)
      :config
      (setq java-ts-mode-indent-offset 2)))

(use-package eglot-java
  :disabled t
  :init
  (fset #'eglot-path-to-uri #'eglot--path-to-uri)
  :bind
  (:map eglot-java-mode-map
        ("C-c l n" . eglot-java-file-new)
        ("C-c l x" . eglot-java-run-main)
        ("C-c l t" . eglot-java-run-test)
        ("C-c l N" . eglot-java-project-new)
        ("C-c l T" . eglot-java-project-build-task)
        ("C-c l R" . eglot-java-project-build-refresh))
  :custom
  (eglot-java-server-install-dir
   (concat user-emacs-directory "var/eclipse.jdt.ls"))

  (eglot-java-junit-platform-console-standalone-jar
   (concat user-emacs-directory
           "var/junit-platform-console-standalone"
           "/junit-platform-console-standalone.jar"))
  (eglot-java-eclipse-jdt-cache-directory
   (concat user-emacs-directory "var/eglot-java-eclipse-jdt-cache")))

(defvar my-google-java-format-jar-file
  (concat (file-name-as-directory (concat user-emacs-directory "var"))
          "google-java-format.jar")
  "Complete path of the google java formatter jar file.")

(defun my-download-latest-google-java-format-jar-file ()
  "Download the latest google java formatter jar file from github."
  (interactive)
  (require 'url)
  (url-retrieve
   "https://github.com/google/google-java-format/releases/latest"
   (lambda (status)
     (when (plist-get status :redirect)
       (let* ((redirect-url (plist-get status :redirect))
              (latest-version (substring redirect-url
                                         (+ 2 (string-search "/v" redirect-url)))))
         (my-download-google-java-format-jar-file latest-version))))))

(defun my-download-google-java-format-jar-file (version)
  "Download the google java formatter jar file of given VERSION from github."
  (let ((url (format (concat "https://github.com"
                             "/google/google-java-format"
                             "/releases/download/v%s/google-java-format-%s-all-deps.jar")
              version version)))
    (url-copy-file url my-google-java-format-jar-file 1)))

(defun my-format-java-buffer ()
  "Format current java buffer to comply with google style."
  (interactive nil 'java-mode)
  (let ((temp-buffer (generate-new-buffer "*java-format*"))
        (temp-file (make-temp-file "java-format-error" nil))
        ;; Always use 'utf-8-unix' & ignore the buffer coding system.
        (default-process-coding-system '(utf-8-unix . utf-8-unix)))
    (call-process-region nil nil "java" nil
                         `(,temp-buffer ,temp-file) nil
                         "-jar" my-google-java-format-jar-file "-")
    (if (> (buffer-size temp-buffer) 0)
        ;; Replace buffer with formatted code
        (replace-buffer-contents temp-buffer)
      (message "Error: could not format current buffer!"))
    (kill-buffer temp-buffer)
    (delete-file temp-file)))

(add-hook 'java-mode-hook #'(lambda () (local-set-key (kbd "C-c l f") #'my-format-java-buffer)))
(add-hook 'java-ts-mode-hook #'(lambda () (local-set-key (kbd "C-c l f") #'my-format-java-buffer)))

(if my-gnu/linux-laptop-p
    (use-package clojure-ts-mode
      :commands (clojure-ts-mode)
      :ensure t)
  (use-package clojure-mode
    :commands (clojure-mode)
    :ensure t))

(use-package cider
  :commands (cider cider-jack-in cider-jack-in-clj cider-jack-in-cljs)
  :ensure t
  :config
  (setq cider-repl-display-help-banner nil))

(if my-gnu/linux-laptop-p
    (use-package go-ts-mode
      :ensure nil
      :mode "\\.go\\'"
      :hook (go-ts-mode . format-all-mode))
  (use-package go-mode
    :ensure t
    :mode "\\.go\\'"
    :hook (go-mode . format-all-mode)))

(if my-gnu/linux-laptop-p
    (use-package rust-ts-mode
      :ensure nil
      :mode "\\.rs\\'"
      :hook (rust-ts-mode . format-all-mode))
  (use-package rust-mode
    :ensure t
    :mode "\\.rs\\'"
    :hook (rust-mode . format-all-mode)))

(use-package format-all
  :commands (format-all-buffer format-all-region format-all-mode)
  :autoload fomat-all-ensure-formatter
  :hook
  (prog-mode . format-all-ensure-formatter)
  (python-ts-mode . format-all-mode)
  (clojure-ts-mode . format-all-mode)
  :config
  (setq-default format-all-formatters
                '(("C" (clang-format "-style=file"))
                  ("C++" (clang-format "-style=file"
                                       "--fallback-style=WebKit"))
                  ("CSS" prettier)
                  ("Emacs Lisp" emacs-lisp)
                  ("Go" gofmt)
                  ("Java" (clang-format "-style=file"))
                  ("JavaScript" prettier)
                  ("Markdown" prettier)
                  ("Python" black)
                  ("TypeScript" prettier))))

(use-package restclient
  :commands (restclient-mode))

(when my-gnu/linux-laptop-p
  (setq major-mode-remap-alist
      '((yaml-mode . yaml-ts-mode)
        (bash-mode . bash-ts-mode)
        (js-mode . js-ts-mode)
        (typescript-mode . typescript-ts-mode)
        (json-mode . json-ts-mode)
        (css-mode . css-ts-mode)
        (python-mode . python-ts-mode))))

(use-package dired
  :ensure nil
  :commands (dired dired-jump)
  :bind (("C-x C-j" . dired-jump)
         ("C-x C-d" . dired))
  :hook
  (dired-mode . dired-hide-details-mode)
  :config
  (setq dired-listing-switches "-lhAX --group-directories-first"))


(use-package all-the-icons-dired
  :commands all-the-icons-dired-mode
  :hook
  (dired-mode . (lambda ()
                  (if (window-system)
                      (all-the-icons-dired-mode)))))

(use-package tab-bar
  :config
  (setq tab-bar-show nil)  ;; don't show the tab-bar
  (setq tab-bar-new-tab-choice t) ;; open the current buffer in new tab
  (setq tab-bar-close-button-show nil)
  (setq tab-bar-new-button-show nil)
  (setq tab-bar-close-last-tab-choice 'tab-bar-mode-disable)
  (tab-bar-mode))

(global-unset-key (kbd "C-x C-b"))
(global-set-key (kbd "C-x C-b") 'ibuffer)

(unless my-android-phone-p
  (use-package olivetti
    :commands olivetti-mode
    :hook
    ((org-mode Info-mode) . olivetti-mode)
    :config
    (set-default 'olivetti-body-width 120)))

(use-package pulse
  :ensure nil  ; built-in package
  :autoload
  (pulse-momentary-highlight-one-line pulse-momentary-highlight-region)
  :config
  (setq pulse-flag t)
  (setq pulse-delay 0.04)
  (set-face-attribute 'pulse-highlight-start-face nil
                      :background "#87ceeb"))


(dolist (command '(scroll-up-command
                   scroll-down-command
                   recenter-top-bottom
                   other-window
                   isearch-repeat-forward
                   isearch-repeat-backward
                   ace-window))
  (advice-add command :after
              (lambda (&rest args)
                "Momentarily highlight current line."
                (pulse-momentary-highlight-one-line (point)))))


(advice-add 'kill-ring-save :after
            (lambda (&rest args)
              "Momentarily highlight currently active region, otherwise the current line."
              (if mark-active
                  (pulse-momentary-highlight-region (region-beginning) (region-end))
                (pulse-momentary-highlight-one-line (point)))))

(when my-gnu/linux-laptop-p
  ;; needed for vc-git-root function
  (require 'vc-git)

  (defun my-launch-terminal ()
    "Launch a terminal in project root or in current working directory."
    (interactive)
    (let* ((term (getenv "TERMINAL"))
           (terminal (if term term "xterm"))
           (filename (buffer-file-name))
           (dir (if filename
                    (vc-git-root filename)
                  nil))
           (default-directory (or dir
                                  default-directory)))
      (start-process "Terminal" nil terminal)))

  (defun my-launch-terminal-in-cwd ()
    "Launch a terminal in the current working directory."
    (interactive)
    (let* ((term (getenv "TERMINAL"))
           (terminal (if term term "xterm")))
      (start-process "Terminal" nil terminal)))

  (global-set-key (kbd "s-t") #'my-launch-terminal))

(setq initial-buffer-choice
      (lambda () (let* ((buf (get-buffer "*dashboard*")))
                   (with-current-buffer buf
                     (revert-buffer))
                   buf)))

(defun my-toggle-titlebar ()
  "Toggle titlebar from selected frame."
  (interactive)
  (let* ((frame (selected-frame))
         (visibility (frame-parameter frame 'undecorated)))
    (set-frame-parameter frame 'undecorated (not visibility))))

(let ((private-config (expand-file-name "private.el" user-emacs-directory)))
  (when (file-exists-p private-config)
    (load-file private-config)))

;; Lower the GC threshold, again
(setq gc-cons-threshold 16000000)
