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
               const toUser = admin.database().ref(environment+ '/users/'+ message.toId + '/token').once('value');
               const fromUser = admin.database().ref(environment+ '/connections/'+ message.toId).once('value');
               const badgeCount = admin.database().ref(environment+ '/last-user-message-read/'+ message.toId).once('value');
                
               return Promise.all([toUser, fromUser, badgeCount])
               .then(results1 => {
                     const token = results1[0].val();
                     const connections = results1[1].val();
                     var impersonatingUserId;
                     for (var key in connections) {
                         const key1 = Object.keys(connections[key])[0];
                         if (key1 == message.fromId) {
                            impersonatingUserId = key;
                            break;
                         }
                     }
                     
                     const unreads = results1[2].val();
                     var total = 0
                     if( unreads != null) {
                        Object.keys(unreads).forEach(function(key) {
                                                  total = total + unreads[key]
                                                  });
                     }
                     const impersonatingUser = admin.database().ref(environment+ '/users/'+ impersonatingUserId + '/name').once('value');
                     
                     return Promise.all([impersonatingUser])
                     .then(results2 => {
                           const fromUserName = results2[0].val();
                           const payload = {
                           notification: {
                           title: fromUserName,
                           body: `${message.message}`,
                           badge: '' + total,
                           sound: 'default'
                           }
                           };
                           return admin.messaging().sendToDevice(token, payload).then(response => {});
                           });
                     
                     });
        });

});


exports.sendChatEndNotification = functions.database.ref(environment+ '/chat-ended/{uid}')
.onCreate(event => {
          const toId = event.params.uid;
          const accountId = Object.keys(event.data.val())[0];
          const code = event.data.val()[accountId];
          var title = '';
          var message = '';
          
          if(code == '00') {
          //title = 'It''s a Tie';
          message = 'You both have failed to guess each other.';
          } else if(code == '01') {
          //title = 'Well Done!';
          message = 'You got\'em and you did not get caught.';
          } else if(code == '10') {
          //title = 'That''s Okey!';
          message = 'You have been caught.';
          } else if(code == '11') {
          //title = 'Well Done!';
          message = 'You both have caught each other.';
          }
          const toUser = admin.database().ref(environment+ '/users/'+ toId + '/token').once('value');
          const account = admin.database().ref(environment+ '/users/'+ accountId + '/name').once('value');
          
          const parentRef = event.data.ref.parent;
          return Promise.all([toUser, account, parentRef.remove()])
          .then(results => {
                const token = results[0].val();
                const name = results[1].val();
                const payload = {
                notification: {
                title: 'Chat ended with ' + name,
                body: message,
                sound: 'default'
                }
                };
            return admin.messaging().sendToDevice(token, payload).then(response => {});
            
        });
});
