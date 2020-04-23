import argparse
from random import randrange

def labirinto_random(lato, occupate):
  totali = lato * lato
  numOccupate = totali * occupate / 100
  ostacoli = []
  n = 0
  f = open("./labirinto_casuale.pl", "w")
  f.write("num_colonne(" + str(lato) + ").\n")
  f.write("num_righe(" + str(lato) + ").\n")
  while(n < numOccupate):
    ostacolo = (randrange(lato)+1, randrange(lato)+1)
    if ostacolo not in ostacoli:
      ostacoli.append(ostacolo)
      f.write("occupata(pos(" + str(ostacolo[0]) + "," + str(ostacolo[1]) + ")).\n")
      n += 1
  ciclo = True
  while(ciclo):
    start = (randrange(lato)+1, randrange(lato)+1)
    if start not in ostacoli:
      f.write("iniziale(pos(" + str(start[0]) + "," + str(start[1]) + ")).\n")
      ciclo = False
  ciclo = True
  while(ciclo):
    goal = (randrange(lato)+1, randrange(lato)+1)
    if goal not in ostacoli:
      f.write("finale(pos(" + str(goal[0]) + "," + str(goal[1]) + ")).\n")
      ciclo = False
  f.close()

def labirinto_file(path):
  with open(path) as toRead:
    labirinto = toRead.readlines()
    toWrite = open("./labirinto_casuale.pl", "w")
    toWrite.write("num_righe(" + str(len(labirinto)) + ").\n")
    toWrite.write("num_colonne(" + str(len(labirinto[0])) + ").\n")
    for i in range(1, len(labirinto) +1):
      for j in range(1, len(labirinto[0]) +1):
        if labirinto[i][j] == "S":
          toWrite.write("iniziale(pos(" + str(i) + "," + str(j) + ")).\n")
        elif labirinto[i][j] == "G":
          toWrite.write("finale(pos(" + str(i) + "," + str(j) + ")).\n")
        elif labirinto[i][j] == "W":
          toWrite.write("occupata(pos(" + str(i) + "," + str(j) + ")).\n")
    toWrite.close()

if __name__ == "__main__":
  parser = argparse.ArgumentParser(description='Scegli se generare un labirinto casuale o da un file di testo')
  parser.add_argument('-r', '--random', nargs=2,type=int, help="Crea un labirinto casuale specificando il lato e la percentuale di caselle occupate [0-100]")
  parser.add_argument('-f', '--file', nargs=1, help="crea un labirinto da file specificando il percorso")
  args = parser.parse_args()
  if "random" in args and args.random != None:
    labirinto_random(args.random[0], args.random[1])
  elif "file" in args and args.file != None:
    labirinto_file(args.file)