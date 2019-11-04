#include<stdlib.h>

void foo (int **a)
{
  *a = malloc(sizeof(int));
}

int main (int argc, char** argv)
{
  int *a;
  foo(&a);
  *a = 42;
  free(a);
  return 0;
}
