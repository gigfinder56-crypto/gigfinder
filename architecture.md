# GigFinder - Architecture & Implementation Plan

## Overview
GigFinder is a comprehensive freelance and internship opportunity platform with ML-based recommendations, admin management, and real-time notifications.

## Core Features (MVP)
1. **Authentication**: Email + OTP verification
2. **User Profile Management**: Detailed profile with role-based fields (student/employee)
3. **Opportunity Categories**: Internships, Projects, Scholarships, Delivery, Tuitions, IT Jobs
4. **ML-Based Recommendations**: Suggestions based on skills, location, interests
5. **Application Management**: Users apply, admin reviews and forwards
6. **Chat System**: Direct user-admin communication
7. **Experience Sharing**: Users share post-job experiences
8. **Admin Dashboard**: Full control over users, applications, datasets, notifications
9. **Notifications**: Push notifications for job suggestions and application status

## Technical Stack
- **Frontend**: Flutter (Mobile App)
- **Storage**: Local Storage using shared_preferences and local JSON files
- **State Management**: Provider pattern
- **ML Integration**: Basic filtering algorithm (skill/location/interest matching)
- **File Handling**: image_picker for photos, file_picker for resumes
- **Notifications**: local_notifications package

## Data Models

### 1. User Model (`lib/models/user.dart`)
```dart
- id: String
- email: String
- name: String
- age: int
- profilePhotoPath: String
- mobileNumber: String
- skills: List<String>
- interests: List<String>
- resumePath: String
- role: String (student/employee)
- location: String
- studentInfo: StudentInfo? (year, college, branch)
- employeeInfo: EmployeeInfo? (company, role, yearsOfExperience)
- others: String
- isProfileComplete: bool
- createdAt: DateTime
- updatedAt: DateTime
```

### 2. Opportunity Model (`lib/models/opportunity.dart`)
```dart
- id: String
- title: String
- category: String (internship, project, scholarship, delivery, tuition, it_job)
- description: String
- company: String
- location: String
- requiredSkills: List<String>
- salary: String
- duration: String
- postedDate: DateTime
- isActive: bool
- createdAt: DateTime
- updatedAt: DateTime
```

### 3. Application Model (`lib/models/application.dart`)
```dart
- id: String
- userId: String
- opportunityId: String
- status: String (pending, reviewing, forwarded, accepted, rejected)
- appliedDate: DateTime
- adminNotes: String
- createdAt: DateTime
- updatedAt: DateTime
```

### 4. ChatMessage Model (`lib/models/chat_message.dart`)
```dart
- id: String
- userId: String
- senderId: String (user or 'admin')
- message: String
- timestamp: DateTime
- isRead: bool
```

### 5. Experience Model (`lib/models/experience.dart`)
```dart
- id: String
- userId: String
- opportunityId: String
- title: String
- content: String
- rating: double
- postedDate: DateTime
- createdAt: DateTime
- updatedAt: DateTime
```

### 6. Notification Model (`lib/models/notification.dart`)
```dart
- id: String
- userId: String
- title: String
- message: String
- type: String (suggestion, application_update, announcement)
- isRead: bool
- timestamp: DateTime
- opportunityId: String?
```

## Service Classes

### 1. AuthService (`lib/services/auth_service.dart`)
- sendOTP(email)
- verifyOTP(email, otp)
- login(email, password)
- logout()
- getCurrentUser()
- isAuthenticated()

### 2. UserService (`lib/services/user_service.dart`)
- createProfile(user)
- updateProfile(user)
- getProfile(userId)
- getAllUsers() // for admin
- isProfileComplete(userId)

### 3. OpportunityService (`lib/services/opportunity_service.dart`)
- getAllOpportunities()
- getOpportunitiesByCategory(category)
- getOpportunityById(id)
- createOpportunity(opportunity) // admin only
- updateOpportunity(opportunity) // admin only
- deleteOpportunity(id) // admin only
- searchOpportunities(query)

### 4. ApplicationService (`lib/services/application_service.dart`)
- submitApplication(application)
- getUserApplications(userId)
- getAllApplications() // admin only
- updateApplicationStatus(id, status) // admin only
- getApplicationById(id)

### 5. ChatService (`lib/services/chat_service.dart`)
- sendMessage(userId, message, senderId)
- getMessages(userId)
- markAsRead(messageId)
- getAllChats() // admin only

### 6. ExperienceService (`lib/services/experience_service.dart`)
- createExperience(experience)
- getExperiencesByOpportunity(opportunityId)
- getAllExperiences()

### 7. NotificationService (`lib/services/notification_service.dart`)
- sendNotification(userId, notification)
- getUserNotifications(userId)
- markAsRead(notificationId)
- clearAll(userId)

### 8. MLRecommendationService (`lib/services/ml_recommendation_service.dart`)
- getRecommendations(userId)
- calculateMatchScore(user, opportunity)
- updateDataset(opportunities) // admin only

## Screen Structure

### Authentication Flow
1. **SplashScreen** (`lib/screens/splash_screen.dart`)
2. **LoginScreen** (`lib/screens/auth/login_screen.dart`)
3. **OTPVerificationScreen** (`lib/screens/auth/otp_verification_screen.dart`)
4. **ProfileSetupScreen** (`lib/screens/auth/profile_setup_screen.dart`)
5. **ProfilePreviewScreen** (`lib/screens/auth/profile_preview_screen.dart`)

### Main App Flow
6. **HomeScreen** (`lib/screens/home/home_screen.dart`) - Dashboard with categories
7. **OpportunitiesListScreen** (`lib/screens/opportunities/opportunities_list_screen.dart`)
8. **OpportunityDetailScreen** (`lib/screens/opportunities/opportunity_detail_screen.dart`)
9. **MyApplicationsScreen** (`lib/screens/applications/my_applications_screen.dart`)
10. **ProfileScreen** (`lib/screens/profile/profile_screen.dart`)
11. **ChatScreen** (`lib/screens/chat/chat_screen.dart`)
12. **ExperiencesScreen** (`lib/screens/experiences/experiences_screen.dart`)
13. **NotificationsScreen** (`lib/screens/notifications/notifications_screen.dart`)

### Admin Flow (Note: Exceeds 12 file limit, will be simplified)
- Admin features will be integrated into existing screens with role-based access

## Implementation Steps

### Phase 1: Foundation & Authentication
1. Set up dependencies (shared_preferences, provider, image_picker, file_picker, flutter_local_notifications)
2. Create all data models with toJson, fromJson, copyWith methods
3. Implement AuthService with mock OTP functionality
4. Build authentication UI screens (Login, OTP, Profile Setup, Profile Preview)
5. Implement profile image and resume upload functionality

### Phase 2: Core Features
6. Create all service classes with local storage implementation
7. Add sample data for opportunities across all categories
8. Build HomeScreen with category cards
9. Implement OpportunitiesListScreen and OpportunityDetailScreen
10. Create application submission flow
11. Build MyApplicationsScreen

### Phase 3: Advanced Features
12. Implement MLRecommendationService with basic matching algorithm
13. Build ChatScreen with user-admin messaging
14. Create ExperiencesScreen for sharing experiences
15. Implement NotificationService and NotificationsScreen
16. Add ProfileScreen with edit functionality

### Phase 4: Polish & Admin Features
17. Integrate admin role checking throughout the app
18. Add admin controls to relevant screens (approve/reject applications, manage opportunities)
19. Implement notification triggers (application status changes, new recommendations)
20. Update theme colors for modern, sleek UI with generous spacing

### Phase 5: Testing & Debugging
21. Run compile_project to check for errors
22. Fix any Dart analysis issues
23. Add platform permissions for camera, file access, notifications
24. Final testing and validation

## File Structure Summary
```
lib/
├── main.dart
├── theme.dart
├── models/
│   ├── user.dart
│   ├── opportunity.dart
│   ├── application.dart
│   ├── chat_message.dart
│   ├── experience.dart
│   └── notification.dart
├── services/
│   ├── auth_service.dart
│   ├── user_service.dart
│   ├── opportunity_service.dart
│   ├── application_service.dart
│   ├── chat_service.dart
│   ├── experience_service.dart
│   ├── notification_service.dart
│   └── ml_recommendation_service.dart
├── screens/
│   ├── splash_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── otp_verification_screen.dart
│   │   ├── profile_setup_screen.dart
│   │   └── profile_preview_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── opportunities/
│   │   ├── opportunities_list_screen.dart
│   │   └── opportunity_detail_screen.dart
│   ├── applications/
│   │   └── my_applications_screen.dart
│   ├── profile/
│   │   └── profile_screen.dart
│   ├── chat/
│   │   └── chat_screen.dart
│   ├── experiences/
│   │   └── experiences_screen.dart
│   └── notifications/
│       └── notifications_screen.dart
└── widgets/
    ├── category_card.dart
    ├── opportunity_card.dart
    └── custom_text_field.dart
```

## Design Guidelines
- **Color Scheme**: Modern gradient-based design with vibrant accent colors
- **Typography**: Google Fonts (Inter) with clear hierarchy
- **Spacing**: Generous padding (16-24px) between elements
- **Components**: Rounded corners, subtle shadows, smooth animations
- **Navigation**: Bottom navigation bar for main sections, custom app bars

## Notes
- Admin account will be a special user with email "admin@gigfinder.com"
- OTP verification will be mocked (any 6-digit code works in local mode)
- ML recommendations use a weighted scoring system: skills (40%), location (30%), interests (30%)
- File uploads store paths locally; in production, these would be cloud URLs
- Chat messages are stored per user in local storage
- Sample data includes 20+ opportunities across all categories
