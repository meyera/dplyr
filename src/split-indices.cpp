#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
std::vector<std::vector<double> > split_indices(IntegerVector group, int groups) {
  std::vector<std::vector<double> > ids(groups);

  int n = group.size();
  for (int i = 0; i < n; ++i) {
    ids[group[i] - 1].push_back(i + 1);
  }

  return ids;
}
