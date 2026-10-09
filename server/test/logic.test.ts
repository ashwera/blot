import { describe,it,expect } from 'vitest';
import { normalize,isNearGuess,maskWord,scoreForGuess } from '../src/game/logic.js';
import { RoomManager } from '../src/rooms/manager.js';
describe('game primitives',()=>{
 it('normalizes Unicode without damaging Devanagari',()=>expect(normalize('  आम! ')).toBe('आम'));
 it('detects a close spelling and rejects unrelated words',()=>{expect(isNearGuess('mangoo','mango')).toBe(true);expect(isNearGuess('train','mango')).toBe(false);});
 it('scores faster guesses more highly',()=>expect(scoreForGuess(5,70)).toBeGreaterThan(scoreForGuess(60,70)));
 it('reveals Unicode code points progressively',()=>expect(maskWord('आम',1)).toBe('आ _'));
 it('creates, joins and cleans up rooms',()=>{const m=new RoomManager();const {room,player}=m.create('Host','en');expect(room.code).toHaveLength(6);const other=m.join(room.code,'Guest');expect(room.players).toHaveLength(2);m.remove(room,player);expect(room.hostId).toBe(other.player.id);m.remove(room,other.player);expect(m.rooms.size).toBe(0);});
});
