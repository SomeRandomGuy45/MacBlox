/*
*
* NOT USED
*
*/

#include <iostream>
#include <unordered_map>
#include <memory>
#include <functional>
#include <string>
#include <cstdlib>
#include <cstdio>
#include "function_wrapper.h"
#include "helper.h"
#include "main_helper.h"

std::unordered_map<std::string, std::unique_ptr<FunctionWrapper>> functionList;