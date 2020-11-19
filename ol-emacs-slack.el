;;; ol-emacs-slack.el --- Support for links to emacs-slack chats in Org mode

;; Copyright (C) 2020 Andrea Giugliano

;; Author: Andrea Giugliano <andrea-dev@hotmail.com>
;; Version: 0.0.0

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; See documentation on https://github.com/ag91/ol-emacs-slack/
(require 'ol)
(require 'dash)
(require 's)

(org-link-set-parameters "emacs-slack"
                         :follow #'ol/slack-follow-link
                         :export #'ol/slack-export
                         :store #'ol/slack-store-link)

(defun ol/slack-format-link (team room &optional timestamp)
  "Format the link to go back to the `ROOM' of the `TEAM', possibly at the `TIMESTAMP'."
  (let (
        (link (format "%s|%s" (slack-team-id team) (oref room id)))
        )
    (when timestamp
      (setq link (format "%s|ts:%s" link timestamp))
      )
    link
    )
  )

(defun ol/slack-parse-link (link)
  "Parse the `LINK' to find the actual team and room objects."
  (let* (
        (split-link (s-split "|" link))
        (team (slack-team-find (first split-link)))
        (room (slack-room-find (second split-link) team))
        (remaining (cddr split-link))
        (res '())
        )
    (setq res (plist-put res :team team))
    (setq res (plist-put res :room room))
    (mapc
     (lambda (elem)
       (let (
             (split-elem (s-split ":" elem))
             )
         (setq res
          (plist-put
           res
           (intern (format ":%s" (first split-elem)))
           (second split-elem)
           )
          )
         )
       )
     remaining
     )
    res
    )
  )

(defun ol/slack-follow-link (link)
  "Follow the link."
  (let (
        (context (ol/slack-parse-link link))
        )
    (slack-room-display (plist-get context :room) (plist-get context :team))
    (when-let (ts (plist-get context :ts))
      (slack-buffer-goto ts))
    )
  )

(defun ol/slack-store-link ()
  "Store a link to a slack group page."
  (when (or (eq major-mode 'slack-message-buffer-mode)
            (eq major-mode 'slack-thread-message-buffer-mode))
    (let* ((buf slack-current-buffer)
           (team (slack-buffer-team buf))
           (team-name (oref team name))
           (room (slack-buffer-room buf))
           (room-name (slack-room-name room team))
           (ts (org-get-at-bol 'ts))
           (formatted_ts (org-get-at-bol 'lui-formatted-time-stamp))
           (link (ol/slack-format-link team room ts))
           (description )
           )
      (org-link-store-props
       :type "emacs-slack"
       :link (concat "emacs-slack:" link)
       :description (concat "Slack message in #" room-name (if formatted_ts (format " at %s" formatted_ts) ""))
       ))))

(defun ol/slack-export (link description format)
  "Export a emacs-slack link from Org files."
  (or description link))

(provide 'ol-emacs-slack)
;;; ol-emacs-slack.el ends here
