# Team Fortress 2: usermessage, events

## UserMessage

**Usermessages have a limit of only 256 bytes!**

### Example

Type | Name    | Description             |
---- | ------- | ----------------------- |
0 | 0  | 0 

### VoteStart - index: 46

Type | Name    | Description             |
---- | ------- | ----------------------- |
byte | team    | Team index or 0 for all |
byte | ent_idx | Client index of person who started the vote, or 99 for the server.                        |     |           |
byte | is_text_chat |

## Event
