# Alifi Admin Dashboard

🏥 **Web-based admin dashboard for managing Alifi pet care platform**

## 🚀 Quick Start

### 1. Access the Dashboard
Open your web browser and navigate to:
```
web/admin-dashboard/index.html
```

### 2. Login Credentials
Use these demo credentials to login:
- **Email:** `admin@alifi.com`
- **Password:** `admin123`

Or use the existing veterinarian account:
- **Email:** `doctor@gmail.com`
- **Password:** `000111`

## 📋 Features

### ✅ **Completed Features:**
- 🔐 **Authentication System** - Secure login with Firebase Auth
- 📊 **Dashboard Overview** - Real-time statistics and recent activity
- 👨‍⚕️ **Veterinarian Management** - Full CRUD operations
- 🔍 **Search & Filter** - Find veterinarians quickly
- 📱 **Responsive Design** - Works on desktop and mobile
- 🔄 **Real-time Updates** - Live data synchronization with Firebase
- 🎨 **Modern UI/UX** - Clean, professional interface

### 🎯 **Veterinarian Management:**
- ➕ **Add New Veterinarians** - Create accounts with email/password
- ✏️ **Edit Information** - Update name, email, phone, specialization
- ⏸️ **Activate/Deactivate** - Control account status
- 🗑️ **Delete Accounts** - Remove veterinarians (with confirmation)
- 📋 **View Details** - Complete veterinarian profiles

### 📊 **Dashboard Statistics:**
- 👨‍⚕️ Total Veterinarians
- 👥 Total Users  
- 🐕 Total Pet Reports
- 💬 Active Chats

### 🔄 **Real-time Features:**
- Live updates when data changes
- Instant notifications for actions
- Real-time statistics
- Activity monitoring

## 🛠️ Technical Details

### **Built With:**
- **Frontend:** Pure HTML5, CSS3, JavaScript (ES6+)
- **Backend:** Firebase (Auth + Firestore)
- **Styling:** Custom CSS with modern design
- **Icons:** Font Awesome 6.0
- **Real-time:** Firebase Firestore listeners

### **Firebase Collections:**
- `veterinarians` - Veterinarian accounts and profiles
- `users` - Regular user accounts
- `petReports` - Lost/found/adoption/breeding reports

### **Security:**
- Firebase Authentication
- Firestore security rules
- Admin-only access control

## 📱 How to Use

### **Login:**
1. Open the dashboard in your browser
2. Enter admin credentials
3. Click "Login"

### **Manage Veterinarians:**
1. Click "Veterinarians" in the sidebar
2. View all registered veterinarians
3. Use "Add Veterinarian" button to create new accounts
4. Use action buttons (Edit/Toggle/Delete) for management

### **Search & Filter:**
- Use the search bar to find specific veterinarians
- Filter by status: All, Active, Inactive
- Results update in real-time

### **Add New Veterinarian:**
1. Click "Add Veterinarian" button
2. Fill in all required fields:
   - Full Name
   - Email
   - Password (for new accounts)
   - Phone Number
   - Specialization
   - Experience
   - License Number (optional)
3. Click "Save Veterinarian"

### **Edit Veterinarian:**
1. Click the edit button (pencil icon) next to any veterinarian
2. Update the information
3. Click "Save Veterinarian"

## 🌐 Browser Support

- ✅ Chrome 80+
- ✅ Firefox 75+
- ✅ Safari 13+
- ✅ Edge 80+

## 🔧 Development

### **File Structure:**
```
web/admin-dashboard/
├── index.html          # Main dashboard page
├── styles.css          # All styling
├── firebase-config.js  # Firebase configuration
├── app.js             # Main application logic
└── README.md          # This file
```

### **Key Functions:**
- `FirebaseService.createVeterinarian()` - Add new vet
- `FirebaseService.updateVeterinarian()` - Update vet info
- `FirebaseService.toggleVeterinarianStatus()` - Activate/deactivate
- `FirebaseService.deleteVeterinarian()` - Remove vet
- `FirebaseService.onVeterinariansChange()` - Real-time updates

## 🚨 Important Notes

1. **Authentication Required:** All features require admin login
2. **Real-time Sync:** Changes appear instantly across all sessions
3. **Data Validation:** All forms include client-side validation
4. **Confirmation Dialogs:** Destructive actions require confirmation
5. **Error Handling:** Comprehensive error messages and recovery

## 🎯 Future Enhancements

- 👥 User Management
- 📊 Advanced Analytics
- 📱 Pet Reports Management
- 💬 Chat System Monitoring
- 📧 Email Notifications
- 📈 Performance Metrics

## 🆘 Troubleshooting

### **Login Issues:**
- Check Firebase configuration
- Verify admin credentials
- Clear browser cache

### **Data Not Loading:**
- Check internet connection
- Verify Firebase project is active
- Check browser console for errors

### **Permissions Error:**
- Ensure user has admin privileges
- Check Firestore security rules

---

🏥 **Alifi Admin Dashboard** - Built with ❤️ for efficient veterinary management 