import os
import fnmatch
import unittest
import webapp2
import importlib
from time import clock
 
class RunUnitTests(webapp2.RequestHandler):
 
    def get(self):        
        self.response.headers['Content-Type'] = 'text/plain'
 
        suite = unittest.TestSuite()
        loader = unittest.TestLoader()
        testCases = self._findTestCases()
        print testCases
 
        for testCase in testCases:
            suite.addTests(loader.loadTestsFromTestCase(testCase))
 
        startTime = clock()
        result = unittest.TextTestRunner(verbosity=2).run(suite)
        stopTime = clock()
 
        self.response.out.write(('Test cases (%d):\n' % len(testCases)) + '\n'.join(map(repr, testCases)) + '\n\n')
        self._printTestResultsGroup(result, 'errors')
        self._printTestResultsGroup(result, 'failures')
 
        self.response.out.write('Total tests: %d\n' % result.testsRun)
        self.response.out.write('Status: %s (%s ms)\n' % ('OK' if result.wasSuccessful() else 'FAILED', (stopTime - startTime) * 1000))
 
    def _findTestCases(self):
        import inspect, sys
        from Test import test_api
        testCases = []
        for class_name, obj in inspect.getmembers(test_api):
            if inspect.isclass(obj):
                testCases.append(getattr(test_api, class_name))
 
        return testCases        
 
    def _printTestResultsGroup(self, result, name):
        result_list = getattr(result, name)
        if len(result_list):
            self.response.out.write("%s (%d):\n" % (name.capitalize(), len(result_list)))
            for item in result_list:
                self.response.out.write('%s\n' % item[0])
            self.response.out.write('\n')
            