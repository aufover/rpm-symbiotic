#include<stdlib.h>
int main (int argc, char** argv)
{
  int *a = malloc(0);
  free (a);
}
