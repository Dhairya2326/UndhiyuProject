const axios = require('axios');

const BASE_URL = 'http://localhost:5000/api/v1';

async function testRoutes() {
  console.log('🚀 Starting Route Integration Test...');
  let hasError = false;

  try {
    // 1. Health Check (Base Server)
    console.log('\nTesting Server Health...');
    try {
        const res = await axios.get('http://localhost:5000/health');
        console.log(`✅ Health Check Passed: ${res.data.message}`);
    } catch (e) {
        console.error(`❌ Health Check Failed: ${e.message}`);
        hasError = true;
    }

    // 2. Menu Routes
    console.log('\nTesting Menu Routes...');
    
    // Create
    let newItemId;
    try {
        const res = await axios.post(`${BASE_URL}/menu`, {
            name: 'Test Item',
            category: 'Snacks',
            price: 50,
            description: 'Test Description'
        });
        if (res.data.success) {
            newItemId = res.data.data.id;
            console.log(`✅ Create Menu Item Passed: ${newItemId}`);
        } else {
            throw new Error('Success false');
        }
    } catch (e) {
        console.error(`❌ Create Menu Item Failed: ${e.message}`);
        hasError = true;
    }

    // Get All
    try {
        await axios.get(`${BASE_URL}/menu`);
        console.log('✅ Get All Menu Items Passed');
    } catch (e) { console.error(`❌ Get All Failed: ${e.message}`); hasError = true; }

    // Get Categories
    try {
        await axios.get(`${BASE_URL}/menu/categories`);
        console.log('✅ Get Categories Passed');
    } catch (e) { console.error(`❌ Get Categories Failed: ${e.message}`); hasError = true; }

    // Get By Category
    try {
        await axios.get(`${BASE_URL}/menu/category/Snacks`);
        console.log('✅ Get By Category Passed');
    } catch (e) { console.error(`❌ Get By Category Failed: ${e.message}`); hasError = true; }

    // Update
    if (newItemId) {
        try {
            await axios.put(`${BASE_URL}/menu/${newItemId}`, { price: 60 });
            console.log('✅ Update Menu Item Passed');
        } catch (e) { console.error(`❌ Update Failed: ${e.message}`); hasError = true; }
    }

    // 3. Billing Routes
    console.log('\nTesting Billing Routes...');

    // Create Bill
    let billId;
    if (newItemId) {
        try {
            const billData = {
                cartItems: [
                    {
                        menuItem: {
                            id: newItemId,
                            name: 'Test Item',
                            category: 'Snacks',
                            price: 60,
                            icon: '🍽️'
                        },
                        quantityInGrams: 500
                    }
                ],
                paymentMethod: 'cash'
            };
            const res = await axios.post(`${BASE_URL}/billing/create`, billData);
            if (res.data.success) {
                billId = res.data.data.id;
                console.log(`✅ Create Bill Passed: ${billId}`);
            }
        } catch (e) {
            console.error(`❌ Create Bill Failed: ${e.message}`);
            // console.error(e.response ? e.response.data : e);
            hasError = true;
        }
    }

    // Get All Bills
    try {
        await axios.get(`${BASE_URL}/billing/all`);
        console.log('✅ Get All Bills Passed');
    } catch (e) { console.error(`❌ Get All Bills Failed: ${e.message}`); hasError = true; }

    // Sales Summary (Previously Broken)
    try {
        const res = await axios.get(`${BASE_URL}/billing/summary/sales`);
        if (res.data.success) {
             console.log('✅ Sales Summary Passed');
        } else {
             throw new Error('Success false');
        }
    } catch (e) { 
        console.error(`❌ Sales Summary Failed: ${e.message}`); 
        if (e.response && e.response.status === 404) console.error('   (Likely Route Ordering Issue)');
        hasError = true; 
    }

    // Top Items
    try {
        await axios.get(`${BASE_URL}/billing/summary/top-items`);
        console.log('✅ Top Items Passed');
    } catch (e) { console.error(`❌ Top Items Failed: ${e.message}`); hasError = true; }

    // Cleanup
    if (newItemId) {
        console.log('\nCleaning up...');
        await axios.delete(`${BASE_URL}/menu/${newItemId}`);
        console.log('✅ Deleted Test Item');
    }
    if (billId) {
        await axios.delete(`${BASE_URL}/billing/${billId}`);
        console.log('✅ Deleted Test Bill');
    }

  } catch (err) {
    console.error('Fatal Test Error:', err);
    hasError = true;
  }

  if (hasError) {
      console.log('\n⚠️  SOME TESTS FAILED');
      process.exit(1);
  } else {
      console.log('\n✨ ALL TESTS PASSED');
      process.exit(0);
  }
}

testRoutes();
