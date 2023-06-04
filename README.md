# Agile.el

`Agile.el` is an Emacs module for managing Agile/Scrum projects using Org mode and Org Agenda.
It helps you to manage your sprints, keep track of your tasks, and monitor your project's progress.

## Installation

To install `agile.el`, download the file and add the following to your Emacs configuration file:

```emacs-lisp
(add-to-list 'load-path "/path/to/agile.el")
(require 'agile)
```

Replace `"/path/to/agile.el"` with the actual path to `agile.el`.

## Configuration

You must configure a root directory for the sprint files:

```emacs-lisp
(setq agile-root-directory "~/notes/org/sprints")
```

## Usage

Under your root directory, create a folder for each project, and within each project folder, create an Org file for each sprint. The sprint file should be in the following format:

```
#+TITLE: Sprint Title
#+STARTDATE: 2023-06-01
#+ENDDATE: 2023-06-14
#+NUMBER: 1

* TODO Task 1
* DONE Task 2
```

The `#+TITLE` is the sprint's title, `#+STARTDATE` and `#+ENDDATE` are the start and end dates of the sprint, and `#+NUMBER` is the sprint number.

You can manage tasks as normal Org mode items.

## Features

- **Show All Sprints**: `M-x agile-show-all-sprints` shows a table of all sprints, including the status (active or done), project name, sprint name, sprint number, the number of done tasks, the number of todo tasks, and the number of days remaining in the sprint (if active).

- **View Current Sprint in Org Agenda**: `M-x agile-agenda-current-sprint` shows the Org Agenda view for the current sprint.

- **Sprint Information in Modeline**: The module shows sprint information, such as how many tasks are done, todo, and how long until the end of the sprint, in the modeline.
