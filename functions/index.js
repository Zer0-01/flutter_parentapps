const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendHomeworkNotification = functions.firestore
    .document("Homework/{homeworkId}")
    .onCreate(async (snap, context) => {
        const data = snap.data(); // Get the data from the newly created document.

        if (data && data.title) {
            const message = {
                notification: {
                    title: "New Homework",
                    body: data.title, // Use the "title" field as the notification body.
                },
                topic: "homeworkNotifications",
            };

            return admin.messaging().send(message);
        }

        return null; // If there's no "title" field, return null to avoid sending a notification.
    });

