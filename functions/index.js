const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.updateIsNewAttendance = functions.firestore
  .document('Students/{studentId}/Attendance/{attendanceDate}')
  .onUpdate(async (change, context) => {
    // Get the data of the document before and after the update
    const oldData = change.before.data();
    const newData = change.after.data();

    // Check if the status field is updated
    const statusUpdated = oldData.status !== newData.status;

    // Check if isNewAttendance is currently false
    const isNewAttendanceFalse = oldData.isNewAttendance === false;

    // Check if isNewAttendance is already true
    const isNewAttendanceTrue = newData.isNewAttendance === true;

    // Update the isNewAttendance field to true only if status is updated and isNewAttendance is currently false
    if (statusUpdated && isNewAttendanceFalse && !isNewAttendanceTrue) {
      // Update the isNewAttendance field to true
      return change.after.ref.update({isNewAttendance: true});
    }

    return null;
  });

exports.updateIsNewHomework = functions.firestore
  .document('Homework/{homeworkId}')
  .onWrite(async (change, context) => {
    // Get the data of the document
    const newData = change.after.data();
    const previousData = change.before.data();

    // Check if the document is newly created or updated
    const isNewDocument = !change.before.exists;

    // Check if isNewHomework is currently false
    const isNewHomeworkFalse = previousData ? !previousData.isNewHomework : true;

    // Check if isNewHomework is already true
    const isNewHomeworkTrue = newData ? newData.isNewHomework : false;

    // Update the isNewHomework field to true only if it was previously false
    if (isNewDocument || (isNewHomeworkFalse && !isNewHomeworkTrue)) {
      // Update the isNewHomework field to true
      return change.after.ref.update({isNewHomework: true});
    }

    return null;
  });

exports.sendNotificationAttendance = functions.firestore
  .document('Students/{studentId}/Attendance/{attendanceId}')
  .onCreate((snap, context) => {
    const attendanceData = snap.data();

    // Extract childrenId from the path
    const childrenId = context.params.studentId;

    const time = attendanceData.time !== null ? attendanceData.time : 'N/A';
    const status = attendanceData.status !== null ? attendanceData.status : 'N/A';

    const attendanceStatus = status === true ? 'Attend' : 'Absent';

    // Create a notification payload
    const payload = {
      notification: {
        title: `New Attendance Upload for ${childrenId}`,
        body: `${context.params.attendanceId} \n Time: ${time} \n Status: ${attendanceStatus}`,
        // Add more notification options as needed
      },
      // Add additional data if needed
      data: {
        // Add custom data here
      },
    };

    // Dynamically create the topic based on childrenId
    const topic = `NotificationAttendance_${childrenId}`;

    // Send the notification to the dynamically created topic
    return admin.messaging().sendToTopic(topic, payload)
      .then((response) => {
        console.log('Notification sent successfully:', response);
        return null;
      })
      .catch((error) => {
        console.error('Error sending notification:', error);
        return null;
      });
  });

exports.sendNotificationHomework = functions.firestore
  .document('Homework/{homeworkId}')
  .onCreate((snap, context) => {
    const homeworkData = snap.data();

    // Extract class, title, and subject from the homework data
    const homeworkClass = homeworkData.class !== null ? homeworkData.class : 'N/A';
    const homeworkTitle = homeworkData.title !== null ? homeworkData.title : 'N/A';
    const homeworkSubject = homeworkData.subject !== null ? homeworkData.subject : 'N/A';

    const homeworkClassWithoutSpace = homeworkClass.replace(/ /g, "_");

    // Create a notification payload for new homework upload
    const payload = {
      notification: {
        title: `New Homework Upload for ${homeworkClass}`,
        body: `Title: ${homeworkTitle}\nSubject: ${homeworkSubject}\nHomework ID: ${context.params.homeworkId}`,
        // Add more notification options as needed
      },
      // Add additional data if needed
      data: {
        // Add custom data here
      },
    };

    // Dynamically create the topic based on homework class
    const topic = `NotificationHomework_${homeworkClassWithoutSpace}`;

    // Send the notification to the dynamically created topic
    return admin.messaging().sendToTopic(topic, payload)
      .then((response) => {
        console.log('Notification sent successfully:', response, topic);
        return null;
      })
      .catch((error) => {
        console.error('Error sending notification:', error);
        return null;
      });
  });

exports.sendNotificationAnnouncementForms = functions.firestore
  .document('Forms/{formId}')
  .onCreate((snap, context) => {
    const formData = snap.data();

    // Extract class, title, and subject from the homework data
    // const formCategories = formData.categories !== null ? formData.categories : 'N/A';
    // const formFileName = formData.fileName !== null ? formData.fileName : 'N/A';
    const formFormType = formData.formType !== null ? formData.formType : 'N/A';
    const formTitle = formData.title !== null ? formData.title : 'N/A';

    // Check if formCategories is equal to "Announcement"
        if (formFormType !== 'Announcement') {
          console.log('Form is not an Announcement. Exiting function.');
          return null;
        }

    // Create a notification payload for new homework upload
    const payload = {
      notification: {
        title: `New Announcement Form`,
        body: `Title: ${formTitle}`,
        // Add more notification options as needed
      },
      // Add additional data if needed
      data: {
        // Add custom data here
      },
    };

    // Dynamically create the topic based on homework class
    const topic = `NotificationAnnouncementForm`;

    // Send the notification to the dynamically created topic
    return admin.messaging().sendToTopic(topic, payload)
      .then((response) => {
        console.log('Notification sent successfully:', response, topic);
        return null;
      })
      .catch((error) => {
        console.error('Error sending notification:', error);
        return null;
      });
  });
