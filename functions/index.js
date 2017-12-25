const functions = require('firebase-functions');
const admin = require('firebase-admin');
const util = require('util');
admin.initializeApp(functions.config().firebase);
const environment = 'production';

exports.sendPushNotification = functions.database.ref(environment+ '/messages/{id}')
.onCreate(event => {
         const messageId = event.params.id;
         const messagePromise = admin.database().ref(environment+ '/messages/'+ messageId).once('value');
         
         return Promise.all([messagePromise])
         .then(results => {
               const message = results[0].val();
               const tokenPromise = admin.database().ref(environment+ '/users/'+ message.toId + '/token').once('value');
               const fromUserPromise = message.fromId.length < message.toId.length ?
               admin.database().ref(environment+ '/anonymous-users/'+ message.fromId + '/' + message.toId).once('value')
               :
               admin.database().ref(environment+ '/users/'+ message.fromId + '/name').once('value');
               
               const readPromise = admin.database().ref(environment+ '/last-user-message-read/'+ message.toId).once('value');
                
               return Promise.all([tokenPromise, readPromise, fromUserPromise])
               .then(results1 => {
                     const token = results1[0].val();
                     const unreads = results1[1].val();
                     var total = 0
                     if( unreads != null) {
                        Object.keys(unreads).forEach(function(key) {
                                                  total = total + unreads[key]
                                                  });
                     }
                     
                     
                     const payload = {
                     notification: {
                     title: results1[2].val(),
                     body: `${message.message}`,
                     badge: '' + total,
                     sound: 'default'
                     }
                     };
                     return admin.messaging().sendToDevice(token, payload).then(response => {});
                     
                     });
        });

});


exports.sendChatEndNotification = functions.database.ref(environment+ '/chat-ended/{uid}')
.onCreate(event => {
          const toId = event.params.uid;
          const code = Object.keys(event.data.val())[0];
          const fromUser = event.data.val()[code];
          
          var message = '';
          
          if(code == 'caught') {
            message = 'You have been caught.';
          } else if(code == 'ended') {
            message = 'The user left the conversation';
          }
          const toUser = admin.database().ref(environment+ '/users/'+ toId + '/token').once('value');
          const ref = event.data.ref;
          return Promise.all([toUser, ref.remove()])
          .then(results => {
                const token = results[0].val();
                const payload = {
                notification: {
                title: 'Chat ended with ' + fromUser,
                body: message,
                sound: 'default'
                }
                };
            return admin.messaging().sendToDevice(token, payload).then(response => {});
            
        });
});
