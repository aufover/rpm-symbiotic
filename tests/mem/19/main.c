#include<stdlib.h>
typedef struct {
  int a;
  void *b;
} foo;


int main (int argc, char** argv)
{
  foo *a = malloc(sizeof(foo));
  a->b = malloc(sizeof(foo));
  free(a->b);
  free(a);
  return 0;
}
