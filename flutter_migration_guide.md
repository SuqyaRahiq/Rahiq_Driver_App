# Flutter App — Simple Migration Guide

---

## 🚗 Part 1: Driver App Changes

### 1. Login Screen & API
Replace **Country Code + Phone Number** with a single **Username** field.

* **Login Endpoint**: `POST /driver/auth/login`
* **Request Body**:
  ```json
  {
    "username": "0512345678",
    "password": "your_password",
    "deviceType": "ANDROID",
    "fcmToken": "fcm_token_here"
  }
  ```
> **Note for Existing Drivers**: For all existing drivers, their `username` is set to their **phone number** (e.g. `0512345678`).

---

### 2. Driver Name Field (`fullName`)
Replace `firstName` + `lastName` with `fullName`.

* **Driver Model (`fromJSON`)**:
  ```dart
  fullName = json['fullName']; // Single full name string
  username = json['username']; // Login username
  ```

* **UI Display**:
  ```dart
  // BEFORE
  Text("${driver.firstName} ${driver.lastName}");

  // AFTER
  Text(driver.fullName);
  ```

---

## 👤 Part 2: Customer / User App Changes

### Order Details API (`GET /orders/:id`)
When fetching order details, the `driver` object now returns `fullName` instead of `firstName` / `lastName`.

* **API Response Structure**:
  ```json
  {
    "id": "order_123",
    "status": "ASSIGNED",
    "driver": {
      "fullName": "Ahmed Al-Rashidi",
      "phoneNumber": "0512345678",
      "avatarUrl": "https://..."
    }
  }
  ```

* **UI Display**:
  ```dart
  // BEFORE
  Text("${subOrder.driver.firstName} ${subOrder.driver.lastName}");

  // AFTER
  Text(subOrder.driver.fullName);
  ```

---

## 📋 Quick Summary Checklist

- [ ] **Driver App Login**: Change login form & API request to send `username` + `password`.
- [ ] **Driver App UI**: Replace `firstName` / `lastName` references with `fullName`.
- [ ] **Customer App UI**: Update Order Details screen to read `subOrder.driver.fullName`.
