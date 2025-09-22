// Firebase Configuration
const firebaseConfig = {
    apiKey: "AIzaSyDrzOlXjtKLa-xsY--c3ijkMbejVJcGIwM",
    authDomain: "bookingplayground-3f74b.firebaseapp.com",
    projectId: "bookingplayground-3f74b",
    storageBucket: "bookingplayground-3f74b.appspot.com",
    messagingSenderId: "470661629842",
    appId: "1:470661629842:android:acba6cbfd1a488abc3e34b"
};

// Initialize Firebase
firebase.initializeApp(firebaseConfig);

// Initialize Firebase services
const auth = firebase.auth();
const db = firebase.firestore();

// Firebase helper functions
const FirebaseService = {
    // Authentication
    async signIn(email, password) {
        try {
            const result = await auth.signInWithEmailAndPassword(email, password);
            return { success: true, user: result.user };
        } catch (error) {
            return { success: false, error: error.message };
        }
    },

    async signOut() {
        try {
            await auth.signOut();
            return { success: true };
        } catch (error) {
            return { success: false, error: error.message };
        }
    },

    // Get current user
    getCurrentUser() {
        return auth.currentUser;
    },

    // Listen to auth state changes
    onAuthStateChanged(callback) {
        return auth.onAuthStateChanged(callback);
    },

    // Veterinarians CRUD operations
    async getVeterinarians() {
        try {
            const snapshot = await db.collection('veterinarians')
                .orderBy('createdAt', 'desc')
                .get();
            
            const vets = [];
            snapshot.forEach(doc => {
                vets.push({
                    id: doc.id,
                    ...doc.data()
                });
            });
            
            return { success: true, data: vets };
        } catch (error) {
            console.error('Error getting veterinarians:', error);
            return { success: false, error: error.message };
        }
    },

    // Listen to veterinarians in real-time
    onVeterinariansChange(callback) {
        return db.collection('veterinarians')
            .orderBy('createdAt', 'desc')
            .onSnapshot(snapshot => {
                const vets = [];
                snapshot.forEach(doc => {
                    vets.push({
                        id: doc.id,
                        ...doc.data()
                    });
                });
                callback(vets);
            });
    },

    async createVeterinarian(vetData) {
        try {
            // Create user account first
            const userCredential = await auth.createUserWithEmailAndPassword(
                vetData.email, 
                vetData.password
            );
            
            const uid = userCredential.user.uid;
            
            // Create veterinarian document
            await db.collection('veterinarians').doc(uid).set({
                uid: uid,
                name: vetData.name,
                email: vetData.email,
                phone: vetData.phone,
                specialization: vetData.specialization,
                experience: vetData.experience,
                license: vetData.license || '',
                isActive: true,
                isOnline: false,
                rating: 0.0,
                totalRatings: 0,
                isVerified: true,
                userType: 'veterinarian',
                createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
                joinDate: new Date().toISOString()
            });

            // Update display name
            await userCredential.user.updateProfile({
                displayName: vetData.name
            });

            return { success: true, id: uid };
        } catch (error) {
            console.error('Error creating veterinarian:', error);
            return { success: false, error: error.message };
        }
    },

    async updateVeterinarian(vetId, vetData) {
        try {
            await db.collection('veterinarians').doc(vetId).update({
                name: vetData.name,
                email: vetData.email,
                phone: vetData.phone,
                specialization: vetData.specialization,
                experience: vetData.experience,
                license: vetData.license || '',
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });

            return { success: true };
        } catch (error) {
            console.error('Error updating veterinarian:', error);
            return { success: false, error: error.message };
        }
    },

    async toggleVeterinarianStatus(vetId, isActive) {
        try {
            await db.collection('veterinarians').doc(vetId).update({
                isActive: isActive,
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });

            return { success: true };
        } catch (error) {
            console.error('Error toggling veterinarian status:', error);
            return { success: false, error: error.message };
        }
    },

    async deleteVeterinarian(vetId) {
        try {
            await db.collection('veterinarians').doc(vetId).delete();
            return { success: true };
        } catch (error) {
            console.error('Error deleting veterinarian:', error);
            return { success: false, error: error.message };
        }
    },

    // Get statistics
    async getStats() {
        try {
            const stats = {
                totalVets: 0,
                totalUsers: 0,
                activeUsers: 0,
                totalStores: 0,
                activeStores: 0,
                totalReports: 0,
                pendingReports: 0,
                totalChats: 0
            };

            // Get veterinarians count
            const vetsSnapshot = await db.collection('veterinarians').get();
            stats.totalVets = vetsSnapshot.size;

            // Get users count and active users
            const usersSnapshot = await db.collection('users').get();
            stats.totalUsers = usersSnapshot.size;
            stats.activeUsers = usersSnapshot.docs.filter(doc => {
                const data = doc.data();
                return data.status !== 'banned';
            }).length;

            // Get stores count and active stores
            const storesSnapshot = await db.collection('petStores').get();
            stats.totalStores = storesSnapshot.size;
            stats.activeStores = storesSnapshot.docs.filter(doc => {
                const data = doc.data();
                return data.isActive === true;
            }).length;

            // Get reports count from all collections
            const reportCollections = ['lost_pets', 'found_pets', 'adoption_pets', 'breeding_pets'];
            let totalReports = 0;
            let pendingReports = 0;
            
            for (const collection of reportCollections) {
                try {
                    const snapshot = await db.collection(collection).get();
                    totalReports += snapshot.size;
                    
                    // Count pending reports
                    const pendingSnapshot = await db.collection(collection)
                        .where('status', 'in', ['pending', 'active'])
                        .get();
                    pendingReports += pendingSnapshot.size;
                } catch (error) {
                    console.warn(`Collection ${collection} not accessible:`, error.message);
                }
            }
            
            stats.totalReports = totalReports;
            stats.pendingReports = pendingReports;

            // Get chats count (mock data for now)
            stats.totalChats = Math.floor(Math.random() * 50) + 10;

            return { success: true, data: stats };
        } catch (error) {
            console.error('Error getting stats:', error);
            return { success: false, error: error.message, data: {
                totalVets: 0,
                totalUsers: 0,
                activeUsers: 0,
                totalStores: 0,
                activeStores: 0,
                totalReports: 0,
                pendingReports: 0,
                totalChats: 0
            }};
        }
    },

    // Pet Stores CRUD operations
    async getPetStores() {
        try {
            const snapshot = await db.collection('petStores')
                .orderBy('createdAt', 'desc')
                .get();
            
            const stores = [];
            snapshot.forEach(doc => {
                stores.push({
                    id: doc.id,
                    ...doc.data()
                });
            });
            
            return { success: true, data: stores };
        } catch (error) {
            console.error('Error getting pet stores:', error);
            return { success: false, error: error.message };
        }
    },

    // Listen to pet stores in real-time
    onPetStoresChange(callback) {
        return db.collection('petStores')
            .orderBy('createdAt', 'desc')
            .onSnapshot(snapshot => {
                const stores = [];
                snapshot.forEach(doc => {
                    stores.push({
                        id: doc.id,
                        ...doc.data()
                    });
                });
                callback(stores);
            });
    },

    async createPetStore(storeData) {
        try {
            const docRef = await db.collection('petStores').add({
                name: storeData.name,
                category: storeData.category,
                phone: storeData.phone,
                email: storeData.email || '',
                address: storeData.address,
                city: storeData.city,
                website: storeData.website || '',
                workingHours: storeData.workingHours || '',
                deliveryAvailable: storeData.deliveryAvailable === 'true',
                description: storeData.description || '',
                imageUrl: storeData.imageUrl || '',
                rating: parseFloat(storeData.rating) || 4.0,
                isActive: true,
                createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });

            return { success: true, id: docRef.id };
        } catch (error) {
            console.error('Error creating pet store:', error);
            return { success: false, error: error.message };
        }
    },

    async updatePetStore(storeId, storeData) {
        try {
            await db.collection('petStores').doc(storeId).update({
                name: storeData.name,
                category: storeData.category,
                phone: storeData.phone,
                email: storeData.email || '',
                address: storeData.address,
                city: storeData.city,
                website: storeData.website || '',
                workingHours: storeData.workingHours || '',
                deliveryAvailable: storeData.deliveryAvailable === 'true',
                description: storeData.description || '',
                imageUrl: storeData.imageUrl || '',
                rating: parseFloat(storeData.rating) || 4.0,
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });

            return { success: true };
        } catch (error) {
            console.error('Error updating pet store:', error);
            return { success: false, error: error.message };
        }
    },

    async togglePetStoreStatus(storeId, isActive) {
        try {
            await db.collection('petStores').doc(storeId).update({
                isActive: isActive,
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });

            return { success: true };
        } catch (error) {
            console.error('Error toggling pet store status:', error);
            return { success: false, error: error.message };
        }
    },

    async deletePetStore(storeId) {
        try {
            await db.collection('petStores').doc(storeId).delete();
            return { success: true };
        } catch (error) {
            console.error('Error deleting pet store:', error);
            return { success: false, error: error.message };
        }
    },

    // Get recent activity
    async getRecentActivity() {
        try {
            const activities = [];
            
            // Get recent veterinarians
            const vetsSnapshot = await db.collection('veterinarians')
                .orderBy('createdAt', 'desc')
                .limit(3)
                .get();
            
            vetsSnapshot.forEach(doc => {
                const data = doc.data();
                activities.push({
                    type: 'new',
                    title: `New veterinarian: ${data.name}`,
                    description: `Added ${data.specialization} specialist`,
                    timestamp: data.createdAt
                });
            });

            // Get recent pet stores
            const storesSnapshot = await db.collection('petStores')
                .orderBy('createdAt', 'desc')
                .limit(3)
                .get();
            
            storesSnapshot.forEach(doc => {
                const data = doc.data();
                activities.push({
                    type: 'new',
                    title: `New pet store: ${data.name}`,
                    description: `Added ${data.category} store in ${data.city}`,
                    timestamp: data.createdAt
                });
            });

            // Sort by timestamp
            activities.sort((a, b) => {
                if (!a.timestamp || !b.timestamp) return 0;
                return b.timestamp.toDate() - a.timestamp.toDate();
            });

            return { success: true, data: activities.slice(0, 5) };
        } catch (error) {
            console.error('Error getting recent activity:', error);
            return { success: false, error: error.message, data: [] };
        }
    },

    // Users Management Functions
    async getUsers() {
        try {
            const snapshot = await db.collection('users')
                .orderBy('createdAt', 'desc')
                .get();
            
            const users = [];
            snapshot.forEach(doc => {
                const data = doc.data();
                users.push({
                    id: doc.id,
                    ...data,
                    createdAt: data.createdAt?.toDate() || new Date(),
                    lastActive: data.lastActive?.toDate() || null
                });
            });
            
            return users;
        } catch (error) {
            console.error('Error fetching users:', error);
            return [];
        }
    },

    async getUserById(userId) {
        try {
            const doc = await db.collection('users').doc(userId).get();
            if (doc.exists) {
                const data = doc.data();
                return {
                    id: doc.id,
                    ...data,
                    createdAt: data.createdAt?.toDate() || new Date(),
                    lastActive: data.lastActive?.toDate() || null
                };
            }
            return null;
        } catch (error) {
            console.error('Error fetching user:', error);
            return null;
        }
    },

    async banUser(userId) {
        try {
            await db.collection('users').doc(userId).update({
                status: 'banned',
                bannedAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });
            console.log('User banned successfully');
        } catch (error) {
            console.error('Error banning user:', error);
            throw error;
        }
    },

    async unbanUser(userId) {
        try {
            await db.collection('users').doc(userId).update({
                status: 'active',
                bannedAt: firebase.firestore.FieldValue.delete(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });
            console.log('User unbanned successfully');
        } catch (error) {
            console.error('Error unbanning user:', error);
            throw error;
        }
    },

    // Reports Management Functions
    async getReports() {
        try {
            const collections = ['lost_pets', 'found_pets', 'adoption_pets', 'breeding_pets'];
            const reports = [];
            
            for (const collectionName of collections) {
                const snapshot = await db.collection(collectionName)
                    .limit(50)
                    .get();
                
                snapshot.forEach(doc => {
                    const data = doc.data();
                    reports.push({
                        id: doc.id,
                        collection: collectionName,
                        type: collectionName.replace('_pets', ''),
                        ...data,
                        createdAt: data.createdAt?.toDate() || new Date(),
                        updatedAt: data.updatedAt?.toDate() || null
                    });
                });
            }
            
            // Sort by creation date
            reports.sort((a, b) => b.createdAt - a.createdAt);
            return reports;
        } catch (error) {
            console.error('Error fetching reports:', error);
            return [];
        }
    },

    async approveReport(reportId, collection) {
        try {
            await db.collection(collection).doc(reportId).update({
                status: 'approved',
                approvedAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });
            console.log('Report approved successfully');
        } catch (error) {
            console.error('Error approving report:', error);
            throw error;
        }
    },

    async rejectReport(reportId, collection) {
        try {
            await db.collection(collection).doc(reportId).update({
                status: 'rejected',
                rejectedAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });
            console.log('Report rejected successfully');
        } catch (error) {
            console.error('Error rejecting report:', error);
            throw error;
        }
    },

    // Settings Management Functions
    async getSettings() {
        try {
            const doc = await db.collection('settings').doc('app').get();
            if (doc.exists) {
                return doc.data();
            }
            return this.getDefaultSettings();
        } catch (error) {
            console.error('Error fetching settings:', error);
            return this.getDefaultSettings();
        }
    },

    async saveSettings(settings) {
        try {
            await db.collection('settings').doc('app').set({
                ...settings,
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            }, { merge: true });
            console.log('Settings saved successfully');
        } catch (error) {
            console.error('Error saving settings:', error);
            throw error;
        }
    },

    getDefaultSettings() {
        return {
            appName: 'Alifi - Pet Care Platform',
            appDescription: 'A comprehensive platform for pet care, adoption, and veterinary services.',
            maintenanceMode: false,
            emailNotifications: true,
            pushNotifications: true,
            adminEmail: 'admin@alifi.com',
            autoApproveReports: false,
            maxImagesPerReport: 5,
            reportExpiryDays: 30
        };
    },

    // Admin Messages Functions
    async sendMessageToUser(userId, messageData) {
        try {
            // Create message document
            const messageDoc = {
                userId: userId,
                subject: messageData.subject,
                content: messageData.content,
                type: messageData.type || 'info',
                isRead: false,
                isAdminMessage: true,
                createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            };

            // Add to admin_messages collection
            const docRef = await db.collection('admin_messages').add(messageDoc);
            
            // Also add to user's notifications
            await db.collection('users').doc(userId).collection('notifications').add({
                ...messageDoc,
                messageId: docRef.id,
                notificationType: 'admin_message'
            });

            console.log('Message sent successfully');
            return { success: true, messageId: docRef.id };
        } catch (error) {
            console.error('Error sending message:', error);
            throw error;
        }
    },

    async getAdminMessages() {
        try {
            const snapshot = await db.collection('admin_messages')
                .orderBy('createdAt', 'desc')
                .get();
            
            const messages = [];
            snapshot.forEach(doc => {
                const data = doc.data();
                messages.push({
                    id: doc.id,
                    ...data,
                    createdAt: data.createdAt?.toDate() || new Date(),
                    updatedAt: data.updatedAt?.toDate() || null
                });
            });
            
            return messages;
        } catch (error) {
            console.error('Error fetching admin messages:', error);
            return [];
        }
    },

    async getUserMessages(userId) {
        try {
            const snapshot = await db.collection('admin_messages')
                .where('userId', '==', userId)
                .orderBy('createdAt', 'desc')
                .get();
            
            const messages = [];
            snapshot.forEach(doc => {
                const data = doc.data();
                messages.push({
                    id: doc.id,
                    ...data,
                    createdAt: data.createdAt?.toDate() || new Date(),
                    updatedAt: data.updatedAt?.toDate() || null
                });
            });
            
            return messages;
        } catch (error) {
            console.error('Error fetching user messages:', error);
            return [];
        }
    },

    async markMessageAsRead(messageId) {
        try {
            await db.collection('admin_messages').doc(messageId).update({
                isRead: true,
                readAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });
            console.log('Message marked as read');
        } catch (error) {
            console.error('Error marking message as read:', error);
            throw error;
        }
    }
};

// Export for use in other files
window.FirebaseService = FirebaseService; 