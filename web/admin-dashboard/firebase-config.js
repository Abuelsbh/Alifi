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
let auth, db, storage;
try {
    if (typeof firebase === 'undefined') {
        console.error('❌ Firebase SDK not loaded! Please check your internet connection.');
        throw new Error('Firebase SDK not loaded');
    }
    
    firebase.initializeApp(firebaseConfig);
    console.log('✅ Firebase initialized successfully');
    
    // Initialize Firebase services
    auth = firebase.auth();
    db = firebase.firestore();
    storage = firebase.storage();
    console.log('✅ Firebase services initialized');
} catch (error) {
    console.error('❌ Error initializing Firebase:', error);
    alert('Error loading Firebase. Please check your internet connection and refresh the page.');
}

// Firebase helper functions
const FirebaseService = {
    // Authentication
    async signIn(email, password) {
        try {
            console.log('🔐 Attempting to sign in with email:', email);
            const result = await auth.signInWithEmailAndPassword(email, password);
            console.log('✅ Sign in successful');
            return { success: true, user: result.user };
        } catch (error) {
            console.error('❌ Sign in error:', error.code, error.message);
            let errorMessage = error.message;
            // Provide user-friendly error messages
            if (error.code === 'auth/user-not-found') {
                errorMessage = 'User not found. Please check your email address.';
            } else if (error.code === 'auth/wrong-password') {
                errorMessage = 'Incorrect password. Please try again.';
            } else if (error.code === 'auth/invalid-email') {
                errorMessage = 'Invalid email address format.';
            } else if (error.code === 'auth/too-many-requests') {
                errorMessage = 'Too many failed login attempts. Please try again later.';
            } else if (error.code === 'auth/network-request-failed') {
                errorMessage = 'Network error. Please check your internet connection.';
            }
            return { success: false, error: errorMessage, code: error.code };
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

    // Check if user is admin from Firestore
    async checkAdminStatus(userId) {
        try {
            console.log('🔍 Checking admin status for user:', userId);
            const userDoc = await db.collection('users').doc(userId).get();
            
            if (!userDoc.exists) {
                console.warn('⚠️ User document not found in Firestore');
                // Fallback: check if email is admin@alifi.com
                const currentUser = auth.currentUser;
                if (currentUser && currentUser.email === 'admin@alifi.com') {
                    console.log('✅ Admin email detected, allowing access');
                    return true;
                }
                return false;
            }
            
            const userData = userDoc.data();
            console.log('📄 User data:', userData);
            
            // Check multiple possible admin indicators
            const isAdmin = 
                (userData.customClaims && userData.customClaims.admin === true) ||
                (userData.isAdmin === true) ||
                (userData.role === 'admin') ||
                (userData.userType === 'admin') ||
                (auth.currentUser && auth.currentUser.email === 'admin@alifi.com');
            
            console.log('✅ Admin status result:', isAdmin);
            return isAdmin;
        } catch (error) {
            console.error('❌ Error checking admin status:', error);
            // Fallback: allow if email is admin@alifi.com
            const currentUser = auth.currentUser;
            if (currentUser && currentUser.email === 'admin@alifi.com') {
                console.log('✅ Fallback: Admin email detected, allowing access');
                return true;
            }
            return false;
        }
    },

    // Veterinarians CRUD operations
    async getVeterinarians() {
        try {
            const snapshot = await db.collection('users')
                .where('userType', '==', 'veterinarian')
                .get();
            
            const vets = [];
            snapshot.forEach(doc => {
                const data = doc.data();
                // Filter out deleted veterinarians
                if (!data.isDeleted) {
                    vets.push({
                        id: doc.id,
                        ...data,
                        // Map fields for compatibility
                        name: data.name || data.username || 'طبيب بيطري',
                        profilePhoto: data.profileImageUrl || data.profilePhoto
                    });
                }
            });
            
            // Sort by createdAt descending (client-side)
            vets.sort((a, b) => {
                const aTime = a.createdAt?.toMillis?.() || (a.createdAt?.seconds || 0) * 1000 || 0;
                const bTime = b.createdAt?.toMillis?.() || (b.createdAt?.seconds || 0) * 1000 || 0;
                return bTime - aTime;
            });
            
            return { success: true, data: vets };
        } catch (error) {
            console.error('Error getting veterinarians:', error);
            return { success: false, error: error.message };
        }
    },

    // Listen to veterinarians in real-time from users collection
    onVeterinariansChange(callback) {
        return db.collection('users')
            .where('userType', '==', 'veterinarian')
            .onSnapshot(snapshot => {
                const vets = [];
                snapshot.forEach(doc => {
                    const data = doc.data();
                    // Filter out deleted veterinarians
                    if (!data.isDeleted) {
                        vets.push({
                            id: doc.id,
                            ...data,
                            // Map fields for compatibility
                            name: data.name || data.username || 'طبيب بيطري',
                            profilePhoto: data.profileImageUrl || data.profilePhoto
                        });
                    }
                });
                // Sort by createdAt descending (client-side)
                vets.sort((a, b) => {
                    const aTime = a.createdAt?.toMillis?.() || 0;
                    const bTime = b.createdAt?.toMillis?.() || 0;
                    return bTime - aTime;
                });
                callback(vets);
            }, error => {
                console.error('Error listening to veterinarians:', error);
                callback([]);
            });
    },

    async createVeterinarian(vetData, adminEmail = null, adminPassword = null) {
        try {
            // Create user account first
            // Note: This will automatically sign in as the new user
            const userCredential = await auth.createUserWithEmailAndPassword(
                vetData.email, 
                vetData.password
            );
            
            const uid = userCredential.user.uid;
            
            // Create veterinarian document in users collection with all veterinarian data
            await db.collection('users').doc(uid).set({
                uid: uid,
                email: vetData.email,
                username: vetData.name,
                name: vetData.name, // Also store as name
                phone: vetData.phone,
                phoneNumber: vetData.phone || null, // Also store as phoneNumber
                specialization: vetData.specialization,
                experience: vetData.experience,
                license: vetData.license || '',
                isActive: true,
                isOnline: false,
                rating: 0.0,
                totalRatings: 0,
                isVerified: true,
                userType: 'veterinarian', // Flag to identify veterinarian
                createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
                lastLoginAt: null,
                joinDate: new Date().toISOString()
            });

            // Update display name
            await userCredential.user.updateProfile({
                displayName: vetData.name
            });

            // Immediately sign out the newly created veterinarian user
            await auth.signOut();
            
            // Wait a moment for the sign out to complete
            await new Promise(resolve => setTimeout(resolve, 200));

            // If admin credentials are provided, sign back in as admin immediately
            if (adminEmail && adminPassword) {
                try {
                    await auth.signInWithEmailAndPassword(adminEmail, adminPassword);
                    // Wait a moment for the sign in to complete
                    await new Promise(resolve => setTimeout(resolve, 200));
                } catch (signInError) {
                    console.error('Error signing back in as admin:', signInError);
                    // Return success anyway - the vet was created
                }
            }

            return { success: true, id: uid };
        } catch (error) {
            console.error('Error creating veterinarian:', error);
            return { success: false, error: error.message };
        }
    },

    async updateVeterinarian(vetId, vetData) {
        try {
            await db.collection('users').doc(vetId).update({
                name: vetData.name,
                username: vetData.name, // Also update username
                email: vetData.email,
                phone: vetData.phone,
                phoneNumber: vetData.phone, // Also update phoneNumber
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
            await db.collection('users').doc(vetId).update({
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
            // Instead of deleting, mark as deleted with flag in users collection
            await db.collection('users').doc(vetId).update({
                isDeleted: true,
                isActive: false,
                deletedAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });
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

            // Get veterinarians count from users collection (excluding deleted)
            const vetsSnapshot = await db.collection('users')
                .where('userType', '==', 'veterinarian')
                .get();
            stats.totalVets = vetsSnapshot.docs.filter(doc => {
                const data = doc.data();
                return !data.isDeleted;
            }).length;

            // Get users count and active users (excluding deleted)
            const usersSnapshot = await db.collection('users').get();
            const nonDeletedUsers = usersSnapshot.docs.filter(doc => {
                const data = doc.data();
                return !data.isDeleted;
            });
            stats.totalUsers = nonDeletedUsers.length;
            stats.activeUsers = nonDeletedUsers.filter(doc => {
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
                workingHours: storeData.workingHours || {},
                deliveryAvailable: storeData.deliveryAvailable === 'true',
                description: storeData.description || '',
                imageUrl: storeData.imageUrl || '',
                rating: parseFloat(storeData.rating) || 4.0,
                locations: storeData.locations && storeData.locations.length > 0 ? storeData.locations : ['all'],
                isActive: true,
                createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });

            console.log('Advertisement created successfully with ID:', docRef.id);
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
                workingHours: storeData.workingHours || {},
                deliveryAvailable: storeData.deliveryAvailable === 'true',
                description: storeData.description || '',
                imageUrl: storeData.imageUrl || '',
                rating: parseFloat(storeData.rating) || 4.0,
                locations: storeData.locations && storeData.locations.length > 0 ? storeData.locations : ['all'],
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
            
            // Get recent veterinarians from users collection
            const vetsSnapshot = await db.collection('users')
                .where('userType', '==', 'veterinarian')
                .orderBy('createdAt', 'desc')
                .limit(3)
                .get();
            
            vetsSnapshot.forEach(doc => {
                const data = doc.data();
                activities.push({
                    type: 'new',
                    title: `New veterinarian: ${data.name || data.username}`,
                    description: `Added ${data.specialization || 'General'} specialist`,
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
                // Filter out deleted users
                if (!data.isDeleted) {
                    users.push({
                        id: doc.id,
                        ...data,
                        createdAt: data.createdAt?.toDate() || new Date(),
                        lastActive: data.lastActive?.toDate() || null
                    });
                }
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
            return { success: true };
        } catch (error) {
            console.error('Error banning user:', error);
            return { success: false, error: error.message };
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
            return { success: true };
        } catch (error) {
            console.error('Error unbanning user:', error);
            return { success: false, error: error.message };
        }
    },

    async deleteUser(userId) {
        try {
            // Instead of deleting, mark as deleted with flag
            await db.collection('users').doc(userId).update({
                isDeleted: true,
                deletedAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });
            console.log('User marked as deleted successfully');
            return { success: true };
        } catch (error) {
            console.error('Error deleting user:', error);
            return { success: false, error: error.message };
        }
    },

    // Admins Management Functions (New Section)
    async getAdmins() {
        try {
            const usersSnapshot = await db.collection('users').get();
            const roles = this.getAdminRoles();
            const admins = [];
            
            for (const doc of usersSnapshot.docs) {
                const userData = doc.data();
                if (userData.customClaims && userData.customClaims.admin === true) {
                    const role = userData.customClaims.role || 'admin';
                    const roleInfo = roles[role] || roles['admin'];
                    
                    admins.push({
                        id: doc.id,
                        uid: doc.id,
                        name: userData.name || userData.email,
                        email: userData.email,
                        role: role,
                        roleName: roleInfo.name,
                        roleDescription: roleInfo.description,
                        permissions: userData.customClaims.permissions || {},
                        lastSignInTime: userData.lastSignInTime?.toDate() || null
                    });
                }
            }
            
            return admins;
        } catch (error) {
            console.error('Error fetching admins:', error);
            return [];
        }
    },

    async createAdmin(email, password, displayName) {
        // WARNING: Setting custom claims from client-side is INSECURE for production apps.
        // This should be done via a Firebase Cloud Function or other secure backend service
        // using the Firebase Admin SDK.
        try {
            // First, check if user exists in Firestore
            const usersQuery = await db.collection('users').where('email', '==', email).get();
            
            if (!usersQuery.empty) {
                // User exists in Firestore, just update their admin status
                const userDoc = usersQuery.docs[0];
                const uid = userDoc.id;
                
                await db.collection('users').doc(uid).update({
                    name: displayName,
                    customClaims: { admin: true },
                    updatedAt: firebase.firestore.FieldValue.serverTimestamp()
                });
                
                return { success: true, uid: uid, message: 'Admin privileges added to existing user' };
            } else {
                // User doesn't exist, create new account
                const userCredential = await auth.createUserWithEmailAndPassword(email, password);
                const uid = userCredential.user.uid;

                // Set custom claim (insecure client-side example)
                // For a secure implementation, call a Cloud Function here:
                // await firebase.functions().httpsCallable('addAdminRole')({ email: email });
                await userCredential.user.getIdToken(true); // Refresh token to get new claims
                // This part where custom claims are directly set client-side is a placeholder and WILL NOT WORK
                // You need a backend call to set custom claims. This mock is for UI integration.
                await db.collection('users').doc(uid).set({
                    email: email,
                    name: displayName,
                    customClaims: { admin: true },
                    createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                    lastSignInTime: firebase.firestore.FieldValue.serverTimestamp()
                }, { merge: true });
                
                return { success: true, uid: uid };
            }
        } catch (error) {
            console.error('Error creating admin:', error);
            
            // If email already exists in Firebase Auth, try to add admin privileges
            if (error.code === 'auth/email-already-in-use') {
                try {
                    // Try to add admin privileges to existing user
                    const privilegeResult = await this.addAdminPrivileges(email, displayName);
                    if (privilegeResult.success) {
                        return { success: true, uid: privilegeResult.uid, message: 'Admin privileges added to existing user' };
                    } else {
                        return { 
                            success: false, 
                            error: 'Email already exists in Firebase Auth but not in Firestore. Please contact support.',
                            code: 'auth-exists-not-firestore'
                        };
                    }
                } catch (privilegeError) {
                    return { 
                        success: false, 
                        error: 'Email already exists but could not add admin privileges. Please contact support.',
                        code: 'privilege-error'
                    };
                }
            }
            
            return { success: false, error: error.message };
        }
    },

    // Add admin privileges to existing user
    async addAdminPrivileges(email, displayName) {
        try {
            // First, check if user exists in Firestore
            const usersQuery = await db.collection('users').where('email', '==', email).get();
            
            if (!usersQuery.empty) {
                // User exists in Firestore, update their admin status
                const userDoc = usersQuery.docs[0];
                const uid = userDoc.id;
                
                await db.collection('users').doc(uid).update({
                    name: displayName,
                    customClaims: { admin: true },
                    updatedAt: firebase.firestore.FieldValue.serverTimestamp()
                });
                
                return { success: true, uid: uid, message: 'Admin privileges added to existing user' };
            } else {
                return { success: false, error: 'User with this email does not exist. Please create a new account.' };
            }
        } catch (error) {
            console.error('Error adding admin privileges:', error);
            return { success: false, error: error.message };
        }
    },

    async removeAdmin(uid) {
        // WARNING: Removing custom claims and deleting users from client-side is INSECURE for production apps.
        // This should be done via a Firebase Cloud Function or other secure backend service
        // using the Firebase Admin SDK.
        try {
            // Remove custom claim (insecure client-side example)
            // For a secure implementation, call a Cloud Function here:
            // await firebase.functions().httpsCallable('removeAdminRole')({ uid: uid });
            await db.collection('users').doc(uid).update({
                'customClaims.admin': firebase.firestore.FieldValue.delete(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });

            // Delete user from authentication
            // Note: Client-side delete only works for the currently signed-in user.
            // To delete other users, you NEED the Admin SDK on a backend.
            // await auth.currentUser.delete(); // This would delete the currently logged in admin!

            // For demonstration, we will just update the Firestore record for the user
            // In a real app, a Cloud Function would delete the Auth user.
            console.warn('Client-side admin removal is incomplete. Implement a Cloud Function for full security.');
            
            return { success: true };
        } catch (error) {
            console.error('Error removing admin:', error);
            return { success: false, error: error.message };
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
                    // IMPORTANT: Use doc.id as the document ID (Firestore auto-generated ID)
                    // The 'id' field in data might be a timestamp, but we need the actual Firestore document ID
                    // Put ...data first, then override 'id' with doc.id to ensure correct ID
                    const reportData = {
                        ...data,
                        id: doc.id, // Override any 'id' field from data with the actual Firestore doc.id
                        collection: collectionName,
                        type: collectionName.replace('_pets', ''),
                        createdAt: data.createdAt?.toDate() || new Date(),
                        updatedAt: data.updatedAt?.toDate() || null
                    };
                    reports.push(reportData);
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

    async getReportById(reportId, collection) {
        try {
            if (!reportId || !collection) {
                console.error('Missing reportId or collection:', { reportId, collection });
                return null;
            }
            
            const doc = await db.collection(collection).doc(reportId).get();
            if (doc.exists) {
                const data = doc.data();
                return {
                    id: doc.id,
                    collection: collection,
                    type: collection.replace('_pets', ''),
                    ...data,
                    createdAt: data.createdAt?.toDate() || new Date(),
                    updatedAt: data.updatedAt?.toDate() || null
                };
            } else {
                console.error('Report document does not exist:', { reportId, collection });
                return null;
            }
        } catch (error) {
            console.error('Error fetching report:', error);
            console.error('Error details:', { reportId, collection, error: error.message });
            return null;
        }
    },

    async approveReport(reportId, collection) {
        try {
            console.log('Approving report:', { reportId, collection });
            const updateData = {
                approvalStatus: 'approved',
                approvedAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            };
            console.log('Update data:', updateData);
            
            await db.collection(collection).doc(reportId).update(updateData);
            
            // Verify the update
            const updatedDoc = await db.collection(collection).doc(reportId).get();
            const updatedData = updatedDoc.data();
            console.log('Report approved successfully. Updated data:', updatedData);
            console.log('approvalStatus after update:', updatedData?.approvalStatus);
            
            return { success: true };
        } catch (error) {
            console.error('Error approving report:', error);
            console.error('Error details:', { reportId, collection, error: error.message, stack: error.stack });
            return { success: false, error: error.message };
        }
    },

    async rejectReport(reportId, collection) {
        try {
            await db.collection(collection).doc(reportId).update({
                approvalStatus: 'rejected',
                rejectedAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });
            console.log('Report rejected successfully');
            return { success: true };
        } catch (error) {
            console.error('Error rejecting report:', error);
            return { success: false, error: error.message };
        }
    },

    async deleteReport(reportId, collection) {
        try {
            await db.collection(collection).doc(reportId).update({
                isActive: false,
                deletedAt: firebase.firestore.FieldValue.serverTimestamp()
            });
            console.log('Report deleted successfully');
            return { success: true };
        } catch (error) {
            console.error('Error deleting report:', error);
            return { success: false, error: error.message };
        }
    },

    async deleteAllReports() {
        try {
            console.log('Deleting all reports permanently from database...');
            const collections = ['lost_pets', 'found_pets', 'adoption_pets', 'breeding_pets'];
            let totalDeleted = 0;
            const batchLimit = 500; // Firestore batch limit

            for (const collectionName of collections) {
                let hasMore = true;
                
                while (hasMore) {
                    // Delete ALL reports regardless of isActive status
                    let query = db.collection(collectionName)
                        .limit(batchLimit);
                    
                    let snapshot = await query.get();
                    
                    if (snapshot.empty) {
                        hasMore = false;
                        break;
                    }
                    
                    // Process batch - DELETE permanently instead of soft delete
                    const batch = db.batch();
                    
                    snapshot.docs.forEach(doc => {
                        batch.delete(doc.ref); // Permanently delete from database
                    });
                    
                    await batch.commit();
                    totalDeleted += snapshot.docs.length;
                    console.log(`Permanently deleted ${snapshot.docs.length} reports from ${collectionName}`);
                    
                    // If we got less than batchLimit, we're done with this collection
                    if (snapshot.docs.length < batchLimit) {
                        hasMore = false;
                    } else {
                        // Get next batch using the last document as cursor
                        const lastDoc = snapshot.docs[snapshot.docs.length - 1];
                        query = db.collection(collectionName)
                            .startAfter(lastDoc)
                            .limit(batchLimit);
                    }
                }
            }
            
            console.log(`Successfully permanently deleted ${totalDeleted} reports in total`);
            return { success: true, deletedCount: totalDeleted };
        } catch (error) {
            console.error('Error deleting all reports:', error);
            return { success: false, error: error.message };
        }
    },

    // Settings Management Functions
    async getSettings() {
        try {
            const doc = await db.collection('settings').doc('app').get();
            if (doc.exists) {
                return { success: true, data: doc.data() };
            }
            return { success: true, data: this.getDefaultSettings() };
        } catch (error) {
            console.error('Error fetching settings:', error);
            return { success: false, error: error.message, data: this.getDefaultSettings() };
        }
    },

    async saveSettings(settings) {
        try {
            await db.collection('settings').doc('app').set({
                ...settings,
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            }, { merge: true });
            console.log('Settings saved successfully');
            return { success: true };
        } catch (error) {
            console.error('Error saving settings:', error);
            return { success: false, error: error.message };
        }
    },

    getDefaultSettings() {
        return {
            appName: 'Alifi - Pet Care Platform',
            appDescription: 'A comprehensive platform for pet care, adoption, and veterinary services.',
            maintenanceMode: false,
            emailNotifications: true,
            pushNotifications: true,
            adminEmail: 'admin3@alifi.com',
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
            return { success: false, error: error.message };
        }
    },

    async sendMessageToAllUsers(messageData, progressCallback) {
        try {
            // Get all users
            const usersSnapshot = await db.collection('users').get();
            const totalUsers = usersSnapshot.size;
            let successCount = 0;
            let failCount = 0;
            
            if (totalUsers === 0) {
                return { success: false, error: 'No users found in the system.' };
            }

            // Process users in batches to avoid overwhelming Firestore
            const batchSize = 10;
            const batches = [];
            
            for (let i = 0; i < usersSnapshot.docs.length; i += batchSize) {
                batches.push(usersSnapshot.docs.slice(i, i + batchSize));
            }

            // Process each batch
            for (let batchIndex = 0; batchIndex < batches.length; batchIndex++) {
                const batch = batches[batchIndex];
                const writeBatch = db.batch();
                
                for (const userDoc of batch) {
                    const userId = userDoc.id;
                    
                    // Create message document
                    const messageDoc = {
                        userId: userId,
                        subject: messageData.subject,
                        content: messageData.content,
                        type: messageData.type || 'info',
                        isRead: false,
                        isAdminMessage: true,
                        isBroadcast: true, // Mark as broadcast message
                        createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
                    };

                    // Add to admin_messages collection
                    const messageRef = db.collection('admin_messages').doc();
                    writeBatch.set(messageRef, messageDoc);
                    
                    // Also add to user's notifications
                    const notificationRef = db.collection('users').doc(userId).collection('notifications').doc();
                    writeBatch.set(notificationRef, {
                        ...messageDoc,
                        messageId: messageRef.id,
                        notificationType: 'admin_message'
                    });
                }
                
                try {
                    await writeBatch.commit();
                    successCount += batch.length;
                } catch (error) {
                    console.error(`Error in batch ${batchIndex}:`, error);
                    failCount += batch.length;
                }
                
                // Report progress
                if (progressCallback) {
                    const progress = Math.round(((batchIndex + 1) / batches.length) * 100);
                    progressCallback(progress, successCount, failCount, totalUsers);
                }
            }

            console.log(`Message sent to ${successCount} users successfully`);
            return { 
                success: true, 
                totalUsers: totalUsers,
                successCount: successCount,
                failCount: failCount
            };
        } catch (error) {
            console.error('Error sending message to all users:', error);
            return { success: false, error: error.message };
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
            return { success: true };
        } catch (error) {
            console.error('Error marking message as read:', error);
            return { success: false, error: error.message };
        }
    },

    // Advertisements Management Functions
    async getAds() {
        try {
            const snapshot = await db.collection('advertisements')
                .where('isActive', '==', true)
                .orderBy('displayOrder', 'asc')
                .limit(10)
                .get();
            
            const ads = [];
            snapshot.forEach(doc => {
                const data = doc.data();
                ads.push({
                    id: doc.id,
                    ...data,
                    createdAt: data.createdAt?.toDate() || new Date(),
                    updatedAt: data.updatedAt?.toDate() || null
                });
            });
            
            return { success: true, data: ads };
        } catch (error) {
            console.error('Error getting ads:', error);
            return { success: false, error: error.message, data: [] };
        }
    },

    async getAllAds() {
        try {
            const snapshot = await db.collection('advertisements')
                .orderBy('createdAt', 'desc')
                .get();
            
            const ads = [];
            snapshot.forEach(doc => {
                const data = doc.data();
                ads.push({
                    id: doc.id,
                    ...data,
                    createdAt: data.createdAt?.toDate() || new Date(),
                    updatedAt: data.updatedAt?.toDate() || null
                });
            });
            
            return { success: true, data: ads };
        } catch (error) {
            console.error('Error getting all ads:', error);
            return { success: false, error: error.message, data: [] };
        }
    },

    async createAd(adData) {
        console.log('createAd called with data:', adData);
        try {
            // Check if we already have 10 ads
            const adsCount = await db.collection('advertisements').get();
            if (adsCount.size >= 10) {
                return { success: false, error: 'Maximum of 10 advertisements allowed' };
            }

            console.log('Adding document to advertisements collection...');
            const docRef = await db.collection('advertisements').add({
                title: adData.title || '',
                description: adData.description || '',
                imageUrl: adData.imageUrl,
                displayOrder: parseInt(adData.displayOrder) || 1,
                isActive: adData.isActive !== false,
                clickUrl: adData.clickUrl || '',
                locations: adData.locations && adData.locations.length > 0 ? adData.locations : ['all'],
                clickCount: 0,
                views: 0,
                createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });

            console.log('Advertisement created successfully with ID:', docRef.id);
            return { success: true, id: docRef.id };
        } catch (error) {
            console.error('Error creating ad:', error);
            return { success: false, error: error.message };
        }
    },

    async updateAd(adId, adData) {
        try {
            await db.collection('advertisements').doc(adId).update({
                title: adData.title || '',
                description: adData.description || '',
                imageUrl: adData.imageUrl,
                displayOrder: parseInt(adData.displayOrder) || 1,
                isActive: adData.isActive !== false,
                clickUrl: adData.clickUrl || '',
                locations: adData.locations && adData.locations.length > 0 ? adData.locations : ['all'],
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });

            return { success: true };
        } catch (error) {
            console.error('Error updating ad:', error);
            return { success: false, error: error.message };
        }
    },

    async toggleAdStatus(adId, isActive) {
        try {
            await db.collection('advertisements').doc(adId).update({
                isActive: isActive,
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });

            return { success: true };
        } catch (error) {
            console.error('Error toggling ad status:', error);
            return { success: false, error: error.message };
        }
    },

    async deleteAd(adId) {
        try {
            await db.collection('advertisements').doc(adId).delete();
            return { success: true };
        } catch (error) {
            console.error('Error deleting ad:', error);
            return { success: false, error: error.message };
        }
    },

    async incrementAdView(adId) {
        try {
            await db.collection('advertisements').doc(adId).update({
                views: firebase.firestore.FieldValue.increment(1)
            });
        } catch (error) {
            console.error('Error incrementing ad view:', error);
        }
    },

    async incrementAdClick(adId) {
        try {
            await db.collection('advertisements').doc(adId).update({
                clickCount: firebase.firestore.FieldValue.increment(1)
            });
        } catch (error) {
            console.error('Error incrementing ad click:', error);
        }
    },

    // Locations CRUD operations
    async getAllLocations() {
        try {
            console.log('📍 Fetching all locations...');
            
            // Try with orderBy first
            let snapshot;
            try {
                snapshot = await db.collection('locations')
                    .orderBy('displayOrder', 'asc')
                    .orderBy('name', 'asc')
                    .get();
            } catch (orderByError) {
                console.warn('⚠️ OrderBy failed, trying simple query:', orderByError);
                // Fallback to simple query
                snapshot = await db.collection('locations').get();
            }
            
            const locations = [];
            snapshot.forEach(doc => {
                const data = doc.data();
                locations.push({
                    id: doc.id,
                    name: data.name || '',
                    description: data.description || '',
                    displayOrder: data.displayOrder || 0,
                    isActive: data.isActive !== false,
                    createdAt: data.createdAt,
                    updatedAt: data.updatedAt
                });
            });
            
            // Sort manually if orderBy failed
            if (snapshot.empty || locations.length > 0) {
                locations.sort((a, b) => {
                    if (a.displayOrder !== b.displayOrder) {
                        return a.displayOrder - b.displayOrder;
                    }
                    return (a.name || '').localeCompare(b.name || '');
                });
            }
            
            console.log(`✅ Found ${locations.length} locations`);
            return { success: true, data: locations };
        } catch (error) {
            console.error('❌ Error getting locations:', error);
            return { success: false, error: error.message };
        }
    },

    async createLocation(locationData) {
        try {
            const locationRef = await db.collection('locations').add({
                name: locationData.name,
                description: locationData.description || '',
                displayOrder: parseInt(locationData.displayOrder) || 0,
                isActive: locationData.isActive !== false,
                createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });

            return { success: true, id: locationRef.id };
        } catch (error) {
            console.error('Error creating location:', error);
            return { success: false, error: error.message };
        }
    },

    async updateLocation(locationId, locationData) {
        try {
            await db.collection('locations').doc(locationId).update({
                name: locationData.name,
                description: locationData.description || '',
                displayOrder: parseInt(locationData.displayOrder) || 0,
                isActive: locationData.isActive !== false,
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });

            return { success: true };
        } catch (error) {
            console.error('Error updating location:', error);
            return { success: false, error: error.message };
        }
    },

    async deleteLocation(locationId) {
        try {
            await db.collection('locations').doc(locationId).delete();
            return { success: true };
        } catch (error) {
            console.error('Error deleting location:', error);
            return { success: false, error: error.message };
        }
    },

    async toggleLocationStatus(locationId, isActive) {
        try {
            await db.collection('locations').doc(locationId).update({
                isActive: isActive,
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });

            return { success: true };
        } catch (error) {
            console.error('Error toggling location status:', error);
            return { success: false, error: error.message };
        }
    },

    // Listen to locations in real-time
    onLocationsChange(callback) {
        return db.collection('locations')
            .orderBy('displayOrder', 'asc')
            .orderBy('name', 'asc')
            .onSnapshot(snapshot => {
                const locations = [];
                snapshot.forEach(doc => {
                    locations.push({
                        id: doc.id,
                        ...doc.data()
                    });
                });
                callback(locations);
            });
    },

    // Admin Roles and Permissions System
    getAdminRoles() {
        return {
            'super_admin': {
                name: 'Super Admin',
                description: 'صلاحيات كاملة - يمكنه إدارة كل شيء',
                permissions: {
                    manage_users: true,
                    manage_veterinarians: true,
                    manage_stores: true,
                    manage_advertisements: true,
                    manage_reports: true,
                    manage_admins: true,
                    manage_settings: true,
                    view_analytics: true
                }
            },
            'admin': {
                name: 'Admin',
                description: 'مدير - صلاحيات إدارية محدودة',
                permissions: {
                    manage_users: true,
                    manage_veterinarians: true,
                    manage_stores: true,
                    manage_advertisements: true,
                    manage_reports: true,
                    manage_admins: false,
                    manage_settings: false,
                    view_analytics: true
                }
            },
            'moderator': {
                name: 'Moderator',
                description: 'مراجع - صلاحيات مراجعة فقط',
                permissions: {
                    manage_users: false,
                    manage_veterinarians: false,
                    manage_stores: false,
                    manage_advertisements: true,
                    manage_reports: false,
                    manage_admins: false,
                    manage_settings: false,
                    view_analytics: false
                }
            }
        };
    },

    // Create admin with specific role
    async createAdminWithRole(email, password, displayName, role = 'admin') {
        try {
            // Validate role
            const roles = this.getAdminRoles();
            if (!roles[role]) {
                return { success: false, error: 'Invalid admin role' };
            }

            // First, check if user exists in Firestore
            const usersQuery = await db.collection('users').where('email', '==', email).get();
            
            if (!usersQuery.empty) {
                // User exists in Firestore, just update their admin status
                const userDoc = usersQuery.docs[0];
                const uid = userDoc.id;
                
                await db.collection('users').doc(uid).update({
                    name: displayName,
                    customClaims: { 
                        admin: true,
                        role: role,
                        permissions: roles[role].permissions
                    },
                    updatedAt: firebase.firestore.FieldValue.serverTimestamp()
                });
                
                return { success: true, uid: uid, message: `Admin privileges added to existing user with role: ${roles[role].name}` };
            } else {
                // User doesn't exist, create new account
                const userCredential = await auth.createUserWithEmailAndPassword(email, password);
                const uid = userCredential.user.uid;

                await userCredential.user.getIdToken(true);
                
                await db.collection('users').doc(uid).set({
                    email: email,
                    name: displayName,
                    customClaims: { 
                        admin: true,
                        role: role,
                        permissions: roles[role].permissions
                    },
                    createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                    lastSignInTime: firebase.firestore.FieldValue.serverTimestamp()
                }, { merge: true });
                
                return { success: true, uid: uid, message: `Admin created successfully with role: ${roles[role].name}` };
            }
        } catch (error) {
            console.error('Error creating admin with role:', error);
            
            if (error.code === 'auth/email-already-in-use') {
                try {
                    const privilegeResult = await this.addAdminPrivileges(email, displayName, role);
                    if (privilegeResult.success) {
                        return { success: true, uid: privilegeResult.uid, message: `Admin privileges added to existing user with role: ${roles[role].name}` };
                    }
                } catch (privilegeError) {
                    return { 
                        success: false, 
                        error: 'Email already exists but could not add admin privileges. Please contact support.',
                        code: 'privilege-error'
                    };
                }
            }
            
            return { success: false, error: error.message };
        }
    },

    // Add admin privileges with role
    async addAdminPrivileges(email, displayName, role = 'admin') {
        try {
            const roles = this.getAdminRoles();
            if (!roles[role]) {
                return { success: false, error: 'Invalid admin role' };
            }

            const usersQuery = await db.collection('users').where('email', '==', email).get();
            
            if (!usersQuery.empty) {
                const userDoc = usersQuery.docs[0];
                const uid = userDoc.id;
                
                await db.collection('users').doc(uid).update({
                    name: displayName,
                    customClaims: { 
                        admin: true,
                        role: role,
                        permissions: roles[role].permissions
                    },
                    updatedAt: firebase.firestore.FieldValue.serverTimestamp()
                });
                
                return { success: true, uid: uid, message: `Admin privileges added with role: ${roles[role].name}` };
            } else {
                return { success: false, error: 'User with this email does not exist. Please create a new account.' };
            }
        } catch (error) {
            console.error('Error adding admin privileges:', error);
            return { success: false, error: error.message };
        }
    },

    // Check if current user has specific permission
    async checkPermission(permission) {
        try {
            const currentUser = auth.currentUser;
            if (!currentUser) return false;

            const userDoc = await db.collection('users').doc(currentUser.uid).get();
            if (!userDoc.exists) return false;

            const userData = userDoc.data();
            if (!userData.customClaims || !userData.customClaims.admin) return false;

            // Super admin has all permissions
            if (userData.customClaims.role === 'super_admin') return true;

            // Check specific permission
            return userData.customClaims.permissions && userData.customClaims.permissions[permission] === true;
        } catch (error) {
            console.error('Error checking permission:', error);
            return false;
        }
    },

    // Get current user's role and permissions
    async getCurrentUserRole() {
        try {
            const currentUser = auth.currentUser;
            if (!currentUser) return null;

            const userDoc = await db.collection('users').doc(currentUser.uid).get();
            if (!userDoc.exists) return null;

            const userData = userDoc.data();
            if (!userData.customClaims || !userData.customClaims.admin) return null;

            return {
                role: userData.customClaims.role || 'admin',
                permissions: userData.customClaims.permissions || {},
                name: userData.name,
                email: userData.email
            };
        } catch (error) {
            console.error('Error getting current user role:', error);
            return null;
        }
    },

    // Upload image to Firebase Storage
    async uploadImage(file, folder, fileName = null) {
        try {
            // Generate unique filename if not provided
            if (!fileName) {
                const timestamp = Date.now();
                const extension = file.name.split('.').pop();
                fileName = `${timestamp}_${Math.random().toString(36).substring(7)}.${extension}`;
            }

            // Create storage reference
            const storageRef = storage.ref().child(`${folder}/${fileName}`);

            // Upload file
            const uploadTask = storageRef.put(file);

            // Return promise that resolves with download URL
            return new Promise((resolve, reject) => {
                uploadTask.on(
                    'state_changed',
                    (snapshot) => {
                        // Progress tracking (optional)
                        const progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
                        console.log(`Upload progress: ${progress.toFixed(1)}%`);
                    },
                    (error) => {
                        console.error('Error uploading image:', error);
                        reject(error);
                    },
                    async () => {
                        // Upload completed successfully
                        try {
                            const downloadURL = await uploadTask.snapshot.ref.getDownloadURL();
                            console.log('Image uploaded successfully:', downloadURL);
                            resolve({ success: true, url: downloadURL });
                        } catch (error) {
                            console.error('Error getting download URL:', error);
                            reject(error);
                        }
                    }
                );
            });
        } catch (error) {
            console.error('Error in uploadImage:', error);
            return { success: false, error: error.message };
        }
    }
};

// Export for use in other files
window.FirebaseService = FirebaseService; 