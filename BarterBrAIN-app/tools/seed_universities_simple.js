/**
 * Simple university seeder using Firebase Emulator or deployed project
 * No service account needed - uses default credentials
 * 
 * Usage:
 * node tools/seed_universities_simple.js
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize with default credentials
admin.initializeApp({
  projectId: 'barterbrain-1254a'
});

const db = admin.firestore();

// Sample universities for testing
const sampleUniversities = [
  {
    id: 'stanford',
    name: 'Stanford University',
    domains: ['stanford.edu'],
    state: 'CA',
    country: 'US',
    alpha_two_code: 'US',
    web_pages: ['https://www.stanford.edu']
  },
  {
    id: 'mit',
    name: 'Massachusetts Institute of Technology',
    domains: ['mit.edu'],
    state: 'MA',
    country: 'US',
    alpha_two_code: 'US',
    web_pages: ['https://www.mit.edu']
  },
  {
    id: 'harvard',
    name: 'Harvard University',
    domains: ['harvard.edu'],
    state: 'MA',
    country: 'US',
    alpha_two_code: 'US',
    web_pages: ['https://www.harvard.edu']
  },
  {
    id: 'berkeley',
    name: 'University of California, Berkeley',
    domains: ['berkeley.edu'],
    state: 'CA',
    country: 'US',
    alpha_two_code: 'US',
    web_pages: ['https://www.berkeley.edu']
  },
  {
    id: 'yale',
    name: 'Yale University',
    domains: ['yale.edu'],
    state: 'CT',
    country: 'US',
    alpha_two_code: 'US',
    web_pages: ['https://www.yale.edu']
  }
];

async function seedUniversities() {
  try {
    console.log('📚 Seeding sample universities...');
    
    const batch = db.batch();
    
    sampleUniversities.forEach(university => {
      const docRef = db.collection('universities').doc(university.id);
      batch.set(docRef, {
        ...university,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    
    await batch.commit();
    
    console.log(`✅ Successfully seeded ${sampleUniversities.length} universities`);
    console.log('Universities added:');
    sampleUniversities.forEach(u => {
      console.log(`  - ${u.name} (${u.domains.join(', ')})`);
    });
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding universities:', error);
    process.exit(1);
  }
}

seedUniversities();

