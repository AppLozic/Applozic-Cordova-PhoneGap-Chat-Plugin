package com.applozic.phonegap;

import android.content.Context;
import android.os.AsyncTask;
import com.applozic.mobicomkit.api.conversation.Message;
import com.applozic.mobicomkit.api.conversation.MobiComConversationService;
import com.applozic.mobicomkit.channel.database.ChannelDatabaseService;
import com.applozic.mobicomkit.contact.database.ContactDatabase;
import com.applozic.mobicommons.people.contact.Contact;
import com.applozic.mobicommons.json.GsonUtils;
import com.applozic.mobicommons.people.channel.Channel;
import com.applozic.phonegap.GetMessageListTask.CustomConversation;

import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

/**
 * Created by reytum on 4/9/17.
 */

public class GetMessageListTask extends AsyncTask<Void, Void, List<CustomConversation>> {

    String error;
    String paramsJson;
    GetMessageListListener listener;
    Context context;
    boolean isLatestMessageRequest = false;

    public GetMessageListTask(String paramsJson, GetMessageListListener listener, Context context) {
        this.listener = listener;
        this.paramsJson = paramsJson;
        this.context = new WeakReference<Context>(context).get();
    }

    @Override
    protected List<CustomConversation> doInBackground(Void... params) {
        MessageParamsModel model = (MessageParamsModel) GsonUtils.getObjectFromJson(paramsJson, MessageParamsModel.class);
        Channel channel = (model.getChannelKey() == null ? null : ChannelDatabaseService.getInstance(context).getChannelByChannelKey(model.getChannelKey()));

        List<Message> messageList;

        MobiComConversationService mobiComConversationService = new MobiComConversationService(context);

        if (channel == null && model.getContactId() == null) {
            isLatestMessageRequest = true;
            messageList = mobiComConversationService.getLatestMessagesGroupByPeople(model.getCreatedAtTime(), model.getSearchString());
        } else {
            messageList = new MobiComConversationService(context).getMessages(model.getStartTime(), model.getEndTime(), new ContactDatabase(context).getContactById(model.getContactId()), channel, model.getConversationId());
        }

        Collections.sort(messageList, new Comparator<Message>() {
            @Override
            public int compare(Message o1, Message o2) {
                return o2.getCreatedAtTime().compareTo(o1.getCreatedAtTime());
            }
        });

        List<String> recList = new ArrayList<String>();
        List<CustomConversation> mList = new ArrayList<CustomConversation>();
                
       if (!messageList.isEmpty()) {
            if (isLatestMessageRequest) {
                for (Message message : messageList) {
                    if ((message.getGroupId() == null || message.getGroupId() == 0) && !recList.contains(message.getContactIds())) {
                        CustomConversation conversation = new CustomConversation();
                        conversation.setMessage(message);
                        conversation.setContact(new ContactDatabase(context).getContactById(message.getContactIds()));
                        mList.add(conversation);
                        recList.add(message.getContactIds());
                    } else if (message.getGroupId() != null && !recList.contains("group" + message.getGroupId())) {
                        CustomConversation conversation = new CustomConversation();
                        conversation.setMessage(message);
                        conversation.setChannel(ChannelDatabaseService.getInstance(context).getChannelByChannelKey(message.getGroupId()));
                        mList.add(conversation);
                        recList.add("group" + message.getGroupId());
                    }
                }
            } else {
                for (Message message : messageList) {
                    CustomConversation conversation = new CustomConversation();
                    conversation.setMessage(message);
                    if (message.getGroupId() == null) {
                        conversation.setContact(new ContactDatabase(context).getContactById(message.getContactIds()));
                    } else {
                        conversation.setChannel(ChannelDatabaseService.getInstance(context).getChannelByChannelKey(message.getGroupId()));
                    }
                    mList.add(conversation);
                }
            }
        }
        return mList;
    }

    @Override
    protected void onPostExecute(List<CustomConversation> messageList) {
        super.onPostExecute(messageList);

        if (!messageList.isEmpty()) {
            listener.onSuccess(messageList.toArray(new CustomConversation[messageList.size()]), context);
        } else {
            listener.onFailure("Some error occurred while fetching messages", context);
        }
    }

    public interface GetMessageListListener {
        void onSuccess(CustomConversation[] messageList, Context context);

        void onFailure(String error, Context context);
    }

    public class CustomConversation{
        private Message message;
        private Channel channel;
        private Contact contact;

        public void setMessage(Message message){
            this.message = message;
        }

        public Message getMessage(){
            return message;
        }

        public void setChannel(Channel channel){
            this.channel = channel;
        }

        public Channel getChannel(){
            return channel;
        }

        public void setContact(Contact contact){
            this.contact = contact;
        }

        public Contact getContact(){
            return contact;
        }
    }
}
