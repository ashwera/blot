import { RoomManager } from '../rooms/manager.js';
import { isNearGuess,maskWord,normalize,scoreForGuess,type Room } from './logic.js';
import type { Stroke } from '../protocol/messages.js';
export class GameEngine {
 onRoundEnd?: (room:Room)=>void;
 constructor(readonly manager:RoomManager,readonly words:Record<string,string[]>,readonly duration=70){}
 choices(room:Room){const pack=this.words[room.language]??this.words.en;if(!pack||pack.length<3)throw new Error('Word pack unavailable');const pool=[...pack].sort(()=>Math.random()-.5).slice(0,3);room.choices=pool;room.phase='CHOOSING_WORD';return pool;}
 choose(room:Room,playerId:string,index:number){if(room.phase!=='CHOOSING_WORD'||room.players[room.drawerIndex]?.id!==playerId)throw new Error('Only the drawer can choose now');if(index<0||index>=3)throw new Error('Invalid word choice');room.word=room.choices?.[index];room.choices=undefined;room.phase='DRAWING';room.strokes=[];room.guessed.clear();room.hinted=0;room.deadline=Date.now()+this.duration*1000;room.timer=setTimeout(()=>this.endRound(room),this.duration*1000);return room.word!;}
 guess(room:Room,playerId:string,text:string){if(room.phase!=='DRAWING'||playerId===room.players[room.drawerIndex]?.id)throw new Error('Guessing is unavailable');if(room.guessed.has(playerId))return {correct:false,duplicate:true,near:false};if(normalize(text)===normalize(room.word??'')){room.guessed.add(playerId);const elapsed=this.duration-Math.max(0,(room.deadline!-Date.now())/1000);const player=room.players.find(p=>p.id===playerId);if(!player)throw new Error('Player not in room');player.score+=scoreForGuess(elapsed,this.duration);room.players[room.drawerIndex].score+=150;if(room.guessed.size===room.players.length-1)this.endRound(room);return {correct:true,duplicate:false,near:false};}return {correct:false,duplicate:false,near:isNearGuess(text,room.word??'')};}
 endRound(room:Room){if(room.phase!=='DRAWING')return; if(room.timer)clearTimeout(room.timer);room.timer=undefined;room.phase='ROUND_END';room.word=undefined;room.choices=undefined;this.onRoundEnd?.(room);}
 next(room:Room){room.round++;if(room.round>=room.players.length){room.phase='GAME_END';return;}room.drawerIndex=(room.drawerIndex+1)%room.players.length;room.phase='CHOOSING_WORD';room.strokes=[];room.guessed.clear();}
 hint(room:Room){if(room.phase!=='DRAWING'||!room.word)return undefined;room.hinted=Math.min([...room.word].filter(c=>/\p{L}/u.test(c)).length-1,room.hinted+1);return maskWord(room.word,room.hinted);}
 addStrokes(room:Room,strokes:Stroke[]){if(room.phase!=='DRAWING')throw new Error('Drawing is unavailable');room.strokes.push(...strokes);}
}
