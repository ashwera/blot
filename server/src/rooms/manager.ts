import { randomBytes, randomUUID } from 'node:crypto';
import type { Room,Player } from '../game/logic.js';
export class RoomManager {
 readonly rooms=new Map<string,Room>();
 create(name:string,language:string,token=randomBytes(24).toString('hex')) {let code='';do{code=randomBytes(4).toString('base64url').toUpperCase().replace(/[^A-Z0-9]/g,'').slice(0,6)}while(code.length!==6||this.rooms.has(code));const id=randomUUID();const p:Player={id,name,token,score:0,connected:true};const room:Room={code,hostId:id,players:[p],language,phase:'LOBBY',round:0,drawerIndex:0,strokes:[],guessed:new Set(),hinted:0};this.rooms.set(code,room);return {room,player:p};}
 join(code:string,name:string,token=randomBytes(24).toString('hex')) {const room=this.rooms.get(code);if(!room)throw new Error('Room not found');if(room.players.length>=8)throw new Error('Room is full');if(room.phase!=='LOBBY')throw new Error('Game already started');const p:Player={id:randomUUID(),name,token,score:0,connected:true};room.players.push(p);return {room,player:p};}
 byToken(token:string){for(const room of this.rooms.values()){const player=room.players.find(p=>p.token===token);if(player)return {room,player};}return undefined;}
 remove(room:Room,player:Player){room.players=room.players.filter(p=>p.id!==player.id);if(!room.players.length){if(room.timer)clearTimeout(room.timer);this.rooms.delete(room.code);return;}if(room.hostId===player.id)room.hostId=room.players[0].id;if(room.phase!=='LOBBY'&&room.players.length<2){if(room.timer)clearTimeout(room.timer);room.phase='GAME_END';}}
}
