import importlib.util,json,pathlib,sys,unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
sp=importlib.util.spec_from_file_location("research_index",ROOT/"tools/research_index.py");m=importlib.util.module_from_spec(sp);sys.modules["research_index"]=m;sp.loader.exec_module(m)
class ResearchIndexTests(unittest.TestCase):
 def stored(self):return json.loads((ROOT/"research_index.json").read_text(encoding="utf-8"))
 def test_stored_index_valid_and_bounded(self):
  x=m.validate_index(self.stored());self.assertLessEqual(x["entry_count"],m.MAX_ENTRIES);self.assertGreater(x["entry_count"],10)
 def test_rebuild_is_deterministic_for_bound_head(self):
  self.assertEqual(m.build_index(ROOT,self.stored()["head"]),self.stored())
 def test_readback_checks_content_digest(self):
  x=self.stored();row=x["entries"][0];raw=m.read_entry(ROOT,x,row["path"]);self.assertEqual(len(raw),row["bytes"])
 def test_traversal_and_unindexed_path_denied(self):
  x=self.stored()
  with self.assertRaises(m.ResearchIndexError):m.read_entry(ROOT,x,"../secret")
  with self.assertRaises(m.ResearchIndexError):m.read_entry(ROOT,x,"badania/not-indexed.bin")
 def test_index_never_executes_corpus(self):
  x=self.stored();self.assertEqual((x["authority_effect"],x["execution_effect"]),("NONE","NONE"))
if __name__=="__main__":unittest.main()
