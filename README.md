# Smart Kangaroo Care System

The Smart Kangaroo Care System is an IoT-based child monitoring solution designed to support Kangaroo Mother Care (KMC) by continuously monitoring an infant’s vital signs using wearable sensors connected to a mobile application.

The system enables parents, caregivers, and healthcare providers to monitor multiple children in real time, quickly identify abnormal health conditions, and respond promptly to emergencies.

---

## Project Overview

Kangaroo Mother Care is a proven method for improving neonatal health, especially for premature and low-birth-weight infants. However, continuous manual monitoring is challenging and prone to delays.

This project integrates wearable sensors, microcontrollers, mobile technology, and cloud services to provide automated, real-time health monitoring for infants under Kangaroo Care.

---

## Objectives

- Monitor infants’ vital signs in real time
- Support monitoring of multiple children simultaneously
- Detect abnormal health conditions early
- Provide instant alerts to caregivers
- Improve safety and efficiency of Kangaroo Mother Care

---

## System Architecture

### Hardware Layer
- Arduino / ESP32 microcontroller
- Temperature sensor
- Heart rate sensor
- Optional sensors (SpO₂, motion sensor)
- Battery and power management module

### Communication Layer
- Bluetooth or Wi-Fi connectivity
- Secure data transmission

### Software Layer
- Mobile application (Flutter)
- Cloud database (Firebase)
- Real-time alert and notification system

---

## Mobile Application Features

- Child profile registration and management
- Support for multiple children
- Real-time vital signs monitoring
- Color-coded health status indicators
- Automatic prioritization of critical cases
- Health trend visualization using graphs
- Sensor battery level monitoring
- Cloud data synchronization

---

## Monitored Vital Signs

- Body Temperature
- Heart Rate
- Optional:
  - Oxygen Saturation (SpO₂)
  - Movement and activity level

---

## Alert System

The system automatically generates alerts when:
- Body temperature exceeds safe thresholds
- Heart rate is abnormal
- Sensor disconnects or stops sending data
- Battery level is low

Alerts are delivered through mobile notifications with sound and vibration.

---

## Multi-Child Support

- Each child is assigned a unique device ID
- Sensor data is securely separated per child
- Children with abnormal readings are highlighted automatically
- Suitable for hospitals, neonatal units, daycare centers, and home use

---

## 👤 Author

**George Chamveka**  
Bachelor of Science in Business and Information Technology  
Malawi University of Science and Technology (MUST)

---

## 📄 License

This project is developed for **academic and educational purposes**.  
All rights reserved © 2025 **George Chamveka**.



