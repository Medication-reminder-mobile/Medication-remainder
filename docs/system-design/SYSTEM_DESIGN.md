# System Design - Medication Reminder App

## Project Overview
This document outlines the complete system design for the Medication Reminder mobile application.

## Modules / Features

### 1. User Management
- User registration and login
- Profile management (name, age, medical conditions, allergies)
- Emergency contact list
- Multi-profile/family support (future)

### 2. Medication Management
- Add, edit, delete medications
- Medication details (name, dosage, form: pill/liquid, strength, instructions)
- Inventory tracking & low stock alerts
- Prescription photo upload

### 3. Scheduling & Reminders
- Flexible scheduling (daily, weekly, specific days, custom interval)
- Multiple reminders per medication
- Snooze, Mark as Taken, Skip options
- Local notifications with sound and vibration

### 4. History & Adherence Tracking
- Log every intake (taken / skipped / missed)
- Adherence statistics and streaks
- Reports and charts
- Data export (CSV/PDF)

### 5. Additional Features
- Offline-first support
- Dark mode & accessibility
- Notification preferences
- Drug interaction warnings (basic)

## Non-Functional Requirements
- Works offline
- Battery efficient
- Privacy focused (health data)
- Fast and responsive UI

## System Components

- User Interface (Flutter)
- Business Logic Layer
- SQLite Database
- Notification System