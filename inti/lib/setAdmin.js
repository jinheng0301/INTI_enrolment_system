const admin = require("firebase-admin");

admin.initializeApp({
    credential: admin.credential.applicationDefault()
});

async function setAdminRole(uid) {
    await admin.auth().setCustomUserClaims(uid, { admin: true });
    console.log("Admin role set for user:", uid);
}

setAdminRole("PUT_ADMIN_UID_HERE");
