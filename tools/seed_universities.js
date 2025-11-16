/**
 * Seed universities from JSON to Firestore
 * 
 * Usage:
 * 1. Make sure you're logged in: firebase login
 * 2. Make sure Firebase project is set: firebase use YOUR_PROJECT_ID
 * 3. Install dependencies: npm install
 * 4. Run: node tools/seed_universities.js
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin SDK
// TODO: Download service account JSON from Firebase Console and save as service-account.json
// Or run with Application Default Credentials if on GCP
try {
  const serviceAccount = require('../service-account.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
} catch (error) {
  console.log('Service account not found, trying default credentials...');
  admin.initializeApp();
}

const db = admin.firestore();

async function seedUniversities() {
  try {
    console.log('📚 Starting university seeding...');
    
    // Read universities JSON
    const jsonPath = path.join(__dirname, '../assets/data/universities_us.json');
    const universitiesData = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));
    
    console.log(`Found ${universitiesData.length} universities to seed`);
    
    // Batch write to Firestore
    const batchSize = 500;
    let count = 0;
    
    for (let i = 0; i < universitiesData.length; i += batchSize) {
      const batch = db.batch();
      const chunk = universitiesData.slice(i, i + batchSize);
      
      chunk.forEach(university => {
        const docRef = db.collection('universities').doc(university.id);
        batch.set(docRef, {
          name: university.name,
          domains: university.domains,
        });
      });
      
      await batch.commit();
      count += chunk.length;
      console.log(`✅ Seeded ${count}/${universitiesData.length} universities`);
    }
    
    console.log('🎉 University seeding completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding universities:', error);
    process.exit(1);
  }
}

seedUniversities();

