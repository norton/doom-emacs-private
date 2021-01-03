;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq user-full-name (getenv "GIT_AUTHOR_NAME")
      user-mail-address (getenv "GIT_AUTHOR_EMAIL")

      doom-scratch-initial-major-mode 'lisp-interaction-mode
      doom-theme 'doom-solarized-dark
      treemacs-width 32

      ;; Line numbers are pretty slow all around. The performance boost of
      ;; disabling them outweighs the utility of always keeping them on.
      display-line-numbers-type nil

      ;; IMO, modern editors have trained a bad habit into us all: a burning
      ;; need for completion all the time -- as we type, as we breathe, as we
      ;; pray to the ancient ones -- but how often do you *really* need that
      ;; information? I say rarely. So opt for manual completion:
      company-idle-delay nil

      ;; lsp-ui-sideline is redundant with eldoc and much more invasive, so
      ;; disable it by default.
      lsp-ui-sideline-enable nil
      lsp-enable-symbol-highlighting nil

      ;; More common use-case
      evil-ex-substitute-global t)

(use-package! atomic-chrome
  :after-call after-focus-change-function
  :config
  (setq atomic-chrome-default-major-mode 'markdown-mode
        atomic-chrome-buffer-open-style 'frame)
  (atomic-chrome-start-server))

(use-package! whitespace
  :init
  (defvar whitespace-cleanup-before-save t)
  (defun my-whitespace-cleanup-before-save ()
    (if whitespace-cleanup-before-save
      (whitespace-cleanup)))
  (dolist (hook '(prog-mode-hook text-mode-hook))
    (add-hook hook #'whitespace-mode))
  (add-hook 'before-save-hook 'my-whitespace-cleanup-before-save)
  ;; Except Markdown
  (add-hook 'markdown-mode-hook
    '(lambda ()
       (set (make-local-variable 'whitespace-cleanup-before-save) nil)))
  :config
  (setq whitespace-line-column 80
        ;;whitespace-style '(face tabs empty trailing lines-tail)
        whitespace-style '(face tabs spaces trailing lines-tail newline)))

(defun whack-whitespace-forward ()
  "Delete all white space from point to the next word."
  (interactive nil)
  (re-search-forward "[ \t\n]+" nil t)
  (replace-match "" nil nil))

(defun un-indent-by-removing-4-spaces ()
  "Remove 4 spaces from beginning of a line."
  (interactive)
  (save-excursion
    (save-match-data
      (beginning-of-line)
      ;; get rid of tabs at beginning of line
      (when (looking-at "^\\s-+")
        (untabify (match-beginning 0) (match-end 0)))
      (when (looking-at "^    ")
        (replace-match "")))))

(defun toggle-comment-on-line ()
  "Comment or uncomment current line."
  (interactive)
  (comment-or-uncomment-region (line-beginning-position) (line-end-position)))

(global-set-key (kbd "M-[") 'whack-whitespace-forward)
(global-set-key (kbd "<backtab>") 'un-indent-by-removing-4-spaces)
(global-set-key (kbd "C-;") 'toggle-comment-on-line)

;;
;;; UI

;; "monospace" means use the system default. However, the default is usually two
;; points larger than I'd like, so I specify size 12 here.
(setq doom-font (font-spec :family "Source Code Pro for Powerline" :size 13)
      doom-variable-pitch-font (font-spec :family "open sans" :size 14))

;; Prevents some cases of Emacs flickering
(add-to-list 'default-frame-alist '(inhibit-double-buffering . t))


;;
;;; Keybinds

(map! :n [tab] (cmds! (and (featurep! :editor fold)
                           (save-excursion (end-of-line) (invisible-p (point))))
                      #'+fold/toggle
                      (fboundp 'evil-jump-item)
                      #'evil-jump-item)
      :v [tab] (cmds! (and (bound-and-true-p yas-minor-mode)
                           (or (eq evil-visual-selection 'line)
                               (not (memq (char-after) (list ?\( ?\[ ?\{ ?\} ?\] ?\))))))
                      #'yas-insert-snippet
                      (fboundp 'evil-jump-item)
                      #'evil-jump-item)

      :leader
      "h L" #'global-keycast-mode
      "f t" #'find-in-dotfiles
      "f T" #'browse-dotfiles)


;;
;;; Modules

(after! ivy
  ;; I prefer search matching to be ordered; it's more precise
  (add-to-list 'ivy-re-builders-alist '(counsel-projectile-find-file . ivy--regex-plus)))

;; Switch to the new window after splitting
(setq evil-split-window-below t
      evil-vsplit-window-right t)

;;; :tools magit
(setq magit-repository-directories '(("~/projects" . 2))
      magit-save-repository-buffers nil
      ;; Don't restore the wconf after quitting magit, it's jarring
      magit-inhibit-save-previous-winconf t
      transient-values '((magit-commit "")
                         (magit-rebase "--autosquash" "")
                         (magit-pull "--rebase" "")))

;;; :lang org
(setq org-directory "~/projects/org/"
      org-archive-location (concat org-directory ".archive/%s::")
      org-roam-directory (concat org-directory "notes/")
      org-roam-db-location (concat org-roam-directory ".org-roam.db")
      org-journal-encrypt-journal t
      org-journal-file-format "%Y%m%d.org"
      org-startup-folded 'overview
      org-ellipsis " [...] ")

;;; :ui doom-dashboard
(setq fancy-splash-image (concat doom-private-dir "splash.png"))
;; Don't need the menu; I know them all by heart
;;(remove-hook '+doom-dashboard-functions #'doom-dashboard-widget-shortmenu)


;;
;;; Language customizations

(custom-theme-set-faces! 'doom-dracula
  `(markdown-code-face :background ,(doom-darken 'bg 0.075))
  `(font-lock-variable-name-face :foreground ,(doom-lighten 'magenta 0.6)))
