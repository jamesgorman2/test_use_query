import {words} from "popular-english-words";
import * as xss from "xss";

export type StartUp = {
  id: string,
  name: string,
}

function getRandomWord(): string {
  return words.getWordAtPosition(
    Math.floor(Math.random() * words.getWordCount())
  );
}

function caps(s: string): string {
  return s[0].toUpperCase() + s.slice(1);
}

export class StartUpGenerator {

  suggest(): string {
    return `${caps(getRandomWord())}${caps(getRandomWord())}`
  }
}

const generator = new StartUpGenerator();

export class StartUps {
  private nextId = 0;
  private readonly startUps: StartUp[] = [];

  add(startUp: StartUp): void {
    this.startUps.push(startUp);
  }

  addNew(name: string): StartUp {
    if (this.startUps.find(s => s.name === name)) {
      throw new Error(`Duplicate startup name ${name}`);
    }

    const startUp: StartUp = {
      id: (this.nextId++).toString(),
      name,
    };

    this.add(startUp);

    return startUp;
  }

  get(id: string): StartUp | undefined {
    return this.startUps[parseInt(id, 10)];
  }

  getAll(cursor: string | undefined | null, limit: number): {cursor?: string, startUps: StartUp[]} {
    const offset = cursor ? this.startUps.findIndex(s => s.id === cursor) + 1 : 0;
    const startUps = offset >= 0 ?
      this.startUps.slice(offset, offset + limit) :
      [];

    const result: {cursor?: string, startUps: StartUp[]} = { startUps };

    if (offset >= 0 && offset + limit < this.startUps.length) {
      result.cursor = startUps[startUps.length - 1].id;
    }

    return result;
  }
}