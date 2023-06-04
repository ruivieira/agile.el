;;; agile.el --- Description of Agile -*- lexical-binding: t; -*-

;; Author: Rui Vieira <ruidevieira@googlemail.com>
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.3"))
;; Keywords: agile, project management
;; URL: https://git.sr.ht/~ruivieira/agile.el

;;; Commentary:

;; An Emacs module for managing Agile/Scrum projects using Org mode and Org Agenda. 
;; It helps you to manage your sprints, keep track of your tasks, and monitor your project's progress.

;;; Code:
(require 'org)
(require 'org-agenda)

(defvar agile-root-folder "~/notes/org/sprints/"
  "Root folder for sprint files.")

(defun agile-get-project-folders ()
  "Get a list of project folders under the root folder."
  (directory-files agile-root-folder t directory-files-no-dot-files-regexp))

(defun agile-get-sprint-files (folder)
  "Get a list of sprint files under a project FOLDER."
  (directory-files folder t directory-files-no-dot-files-regexp))

(defun agile-parse-sprint-file (file)
  "Parse the sprint FILE and return its metadata."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (let ((title (when (re-search-forward "^#\\+TITLE: \\(.*\\)$" nil t)
                   (match-string 1)))
          (startdate (when (re-search-forward "^#\\+STARTDATE: \\(.*\\)$" nil t)
                       (match-string 1)))
          (enddate (when (re-search-forward "^#\\+ENDDATE: \\(.*\\)$" nil t)
                     (match-string 1)))
          (number (when (re-search-forward "^#\\+NUMBER: \\(.*\\)$" nil t)
                    (match-string 1))))
      (list :file file :title title :startdate startdate :enddate enddate :number number))))

(defun agile-get-all-sprints ()
  "Get a list of all sprint files and their metadata."
  (let (sprints)
    (dolist (project-folder (agile-get-project-folders))
      (dolist (file (agile-get-sprint-files project-folder))
        (let ((metadata (agile-parse-sprint-file file)))
          (push (append metadata (list :project (file-name-nondirectory project-folder))) sprints))))
    sprints))

(setq org-agenda-files (mapcar (lambda (sprint) (plist-get sprint :file)) (agile-get-all-sprints)))

(defun agile-add-task-to-current-sprint (task)
  "Add TASK to the current sprint."
  (interactive "sTask: ")
  (let ((current-sprint-file (car (agile-get-sprint-files (car (agile-get-project-folders))))))
    (with-current-buffer (find-file-noselect current-sprint-file)
      (goto-char (point-max))
      (insert "\n* TODO " task)
      (save-buffer))))

(defun agile-sprint-info ()
  "Gather information about the current sprint."
  (let ((current-sprint-file (car (agile-get-sprint-files (car (agile-get-project-folders)))))
        todo done)
    (with-current-buffer (find-file-noselect current-sprint-file)
      (goto-char (point-min))
      (while (re-search-forward "^\\* TODO " nil t)
        (setq todo (1+ (or todo 0))))
      (goto-char (point-min))
      (while (re-search-forward "^\\* DONE " nil t)
        (setq done (1+ (or done 0))))
      (list :todo todo :done done))))

(setq-default mode-line-format
              (list ""
                    '(:eval (let ((info (agile-sprint-info)))
                              (format " Sprint: TODO %d, DONE %d"
                                      (plist-get info :todo)
                                      (plist-get info :done))))))

(defun agile-get-current-sprint ()
  "Get the current sprint and its metadata."
  (let ((current-sprint-file (agile-get-current-sprint-file)))
    (if current-sprint-file
        (agile-parse-sprint-file current-sprint-file)
      (error "No current sprint file found."))))

(defun agile-date-difference (start end)
  "Calculate the number of days between START and END."
  (let* ((start-date (date-to-time (concat start " 00:00")))
         (end-date (date-to-time (concat end " 00:00"))))
    (/ (float-time (time-subtract end-date start-date)) 86400))) ;; 86400 is the number of seconds in a day


(defun agile-get-current-sprint-file ()
  "Get the current sprint file."
  (car (sort (agile-get-sprint-files (car (agile-get-project-folders))) #'string-greaterp)))

(defun agile-agenda-current-sprint ()
  "Open org-agenda view for the current sprint."
  (interactive)
  (let* ((current-sprint (agile-get-current-sprint))
         (start-date (plist-get current-sprint :startdate))
         (end-date (plist-get current-sprint :enddate))
         (org-agenda-files (list (plist-get current-sprint :file)))
         (org-agenda-start-day start-date)
         (org-agenda-span (max 1 (round (agile-date-difference start-date end-date)))))
    (org-agenda nil "a")))

(require 'tabulated-list)

(defun agile-show-all-sprints ()
  "Show a table of all sprints for all projects."
  (interactive)
  (let* ((current-date (current-time))
         (sprints (agile-get-all-sprints))
         (entries (mapcar (lambda (sprint)
                            (let* ((file (plist-get sprint :file))
                                   (project (plist-get sprint :project))
                                   (title (plist-get sprint :title))
                                   (number (plist-get sprint :number))
                                   (startdate (date-to-time (concat (plist-get sprint :startdate) " 00:00")))
                                   (enddate (date-to-time (concat (plist-get sprint :enddate) " 00:00")))
                                   (active (and (time-less-p startdate current-date)
                                                (time-less-p current-date enddate)))
                                   (remaining-days (if active
                                                       (floor (time-to-seconds (time-subtract enddate current-date)) 86400)
                                                     ""))
                                   (task-info (with-current-buffer (find-file-noselect file)
                                                (agile-sprint-info)))
                                   (done (or (plist-get task-info :done) 0))
                                   (todo (or (plist-get task-info :todo) 0)))
                              (list file (vector (if active "Active" "Done")
                                                 project
                                                 title
                                                 number
                                                 (number-to-string done)
                                                 (number-to-string todo)
                                                 (if active (number-to-string remaining-days) "")))))
                          sprints)))
    (with-current-buffer (get-buffer-create "*Agile Sprints*")
      (tabulated-list-mode)
      (setq tabulated-list-format [("Status" 10 t)
                                   ("Project" 20 t)
                                   ("Sprint" 20 t)
                                   ("Number" 10 t)
                                   ("Done" 10 t)
                                   ("Todo" 10 t)
                                   ("Days Left" 10 t)])
      (setq tabulated-list-entries entries)
      (tabulated-list-init-header)
      (tabulated-list-print)
      (local-set-key (kbd "<return>") (lambda ()
                                        (interactive)
                                        (find-file (tabulated-list-get-id)))) 
      (switch-to-buffer "*Agile Sprints*"))))



(provide 'agile)
;;; agile.el ends here