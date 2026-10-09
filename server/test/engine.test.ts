import { afterEach,describe,it,expect,vi } from 'vitest';
import { RoomManager } from '../src/rooms/manager.js';
import { GameEngine } from '../src/game/engine.js';
describe('authoritative game engine',()=>{
 afterEach(()=>vi.useRealTimers());
 function setup(){const manager=new RoomManager();const {room,player:drawer}=manager.create('Drawer','en');const guesser=manager.join(room.code,'Guesser').player;manager.join(room.code,'Another');const engine=new GameEngine(manager,{en:['mango','train','kite']},60);engine.choices(room);return {room,drawer,guesser,engine};}
 it('delivers the selected secret to the drawer flow and transitions into drawing',()=>{const {room,drawer,engine}=setup();const secret=engine.choose(room,drawer.id,room.choices!.indexOf('mango'));expect(secret).toBe('mango');expect(room.phase).toBe('DRAWING');expect(room.choices).toBeUndefined();expect(room.word).toBe('mango');engine.endRound(room);});
 it('rejects non-drawer word selection and drawer guesses',()=>{const {room,drawer,guesser,engine}=setup();expect(()=>engine.choose(room,guesser.id,0)).toThrow();engine.choose(room,drawer.id,0);expect(()=>engine.guess(room,drawer.id,'mango')).toThrow();engine.endRound(room);});
 it('normalizes punctuation and prevents duplicate scoring',()=>{const {room,drawer,guesser,engine}=setup();engine.choose(room,drawer.id,room.choices!.indexOf('mango'));expect(engine.guess(room,guesser.id,'MANGO!').correct).toBe(true);const score=guesser.score;expect(engine.guess(room,guesser.id,'mango').duplicate).toBe(true);expect(guesser.score).toBe(score);});
 it('ends a round when its server timer expires',()=>{vi.useFakeTimers();const {room,drawer,engine}=setup();engine.choose(room,drawer.id,0);vi.advanceTimersByTime(60_000);expect(room.phase).toBe('ROUND_END');});
});
