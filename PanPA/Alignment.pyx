# distutils: language=c++

import sys
import logging
from PanPA.Graph cimport Graph
from PanPA.Node cimport Node


cdef class Alignment:
    def __init__(self, read_name, read_len, alignment_score):
        self.read_name = read_name
        self.read_len = read_len
        self.alignment_score = alignment_score
        self.path = []
        self.info = []
        self.n_matches = 0
        self.n_mismatches = 0
        self.n_indels = 0
        self.id_score = 0
        self.gaf = ""


    cdef void prepare_aa_gaf(self, Graph graph) except *:
        """
        Outputs alignment in GAF format, either to std output or to a file
        :param graph: is a graph object
        :param output_file: is an opened file with "w" object
        :param stdout: boolean to whether to write to stdout or not
        """
        if not self.info:
            logging.error("No GAF for this alignment, the info is {}".format(self.read_name))
            sys.exit()

        cdef Node node

        # todo I can just loop backwards instead of reversing everytime
        self.info.reverse()
        self.path.reverse()

        # print(f"I am in prepare gaf and info is reverse and it is {self.info}")
        # should never reach this point
        # if (output_file is None) and (stdout is False):
        #     print("You need to either give an output alignment file or True for stdout to print the alignment")
        #     sys.exit()

        gaf_string = [self.read_name, self.read_len, self.info[0]["read_pos"], self.info[-1]["read_pos"] + 1, "+"]

        # adding the path
        path = []
        path_seq_len = 0
        for n in self.path:
            if not path:
                node = graph.nodes[n]
                # path_seq_len += len(node.seq)
                path.append(n)
            elif not path[-1] == n:
                # path_seq_len += len(node.seq)
                path.append(n)
            else:
                continue

        for p in path:
            node = graph.nodes[p]
            path_seq_len += len(node.seq)
        path = "".join([">" + str(x) for x in path])

        gaf_string.append(path)
        # for n in alignment.path:
        #     path_seq_len += len(self.graph.nodes[n].seq)
        gaf_string.append(path_seq_len)

        # for now I'll keep it related to the number of nodes in path
        gaf_string += [self.info[0]["node_pos"], self.info[0]["node_pos"] + len(self.path)]


        gaf_string.append(int(self.n_matches))
        # I think I need to add +1 here because it's [start, end[
        # so like when you say in python3 range(1,5) you get a count until 4
        gaf_string.append(len(self.info))
        gaf_string.append(255)

        # identity = round(self.n_matches/len(self.info), 5)
        # I added some tags, as for alignment score (the score in the DP table)
        # dv for per-base sequence divergence (I think it's 1 - identity)
        # id for sequence identity
        # Maybe add tp:A:(P, S) for primary or secondary alignment
        # cm:i number of minimizers (maybe see how many seeds from the read hit that graph)
        # NM:i total numbers of mismatches and gaps (indels)
        # print(f"calculating the id_score from n matches {self.n_matches}")
        self.id_score = self.n_matches / float(len(self.info))
        gaf_string.append(f"NM:i:{self.n_indels + self.n_mismatches}")
        gaf_string.append(f"AS:i:{str(self.alignment_score)}")
        gaf_string.append(f"dv:f:{str(round(1-self.id_score, 4))}")
        gaf_string.append(f"id:f:{str(round(self.id_score, 4))}")
        # previous = (alignment.info[0]["cigar"], 1)
        previous = []
        cigar = "cg:Z:"
        cigar_symbols = ["I", "D", "=", "X"]
        # pdb.set_trace()
        for item in self.info:
            if not previous:
                previous = [item["type"], 1]

            elif item["type"] == previous[0]:
                previous[1] += 1
            else:
                cigar += str(previous[1]) + cigar_symbols[previous[0]]  # first letter (M, I, D)
                previous = [item["type"], 1]
        cigar += str(previous[1]) + cigar_symbols[previous[0]]

        gaf_string.append(cigar)

        # adding graph name as an extra tag
        gaf_string.append(f"GR:Z:{graph.name}")

        self.gaf = "\t".join([str(x) for x in gaf_string])


    cdef void prepare_dna_gaf(self, Graph graph) except *:
        """
        Outputs alignment in GAF format, either to std output or to a file
        :param graph: is a graph object
        :param output_file: is an opened file with "w" object
        :param stdout: boolean to whether to write to stdout or not
        """
        if not self.info:
            logging.error("No GAF for this alignment, the info is {}".format(self.read_name))
            sys.exit()

        cdef Node node

        # todo I can just loop backwards instead of reversing everytime
        self.info.reverse()
        self.path.reverse()

        # print(f"I am in prepare gaf and info is reverse and it is {self.info}")
        # should never reach this point
        # if (output_file is None) and (stdout is False):
        #     print("You need to either give an output alignment file or True for stdout to print the alignment")
        #     sys.exit()

        gaf_string = [self.read_name, self.read_len, self.info[0]["read_pos"], self.info[-1]["read_pos"] + 1, "+"]

        # adding the path
        path = []
        for n in self.path:
            if not path:
                node = graph.nodes[n]
                # path_seq_len += len(node.seq)
                path.append(n)
            elif not path[-1] == n:
                # path_seq_len += len(node.seq)
                path.append(n)
            else:
                continue

        path_seq_len = 0
        for p in path:
            node = graph.nodes[p]
            path_seq_len += len(node.seq)
        path = "".join([">" + str(x) for x in path])

        gaf_string.append(path)
        # for n in alignment.path:
        #     path_seq_len += len(self.graph.nodes[n].seq)
        gaf_string.append(path_seq_len)

        # for now I'll keep it related to the number of nodes in path
        gaf_string += [self.info[0]["node_pos"], self.info[0]["node_pos"] + len(self.path)]

        gaf_string.append(int(self.n_matches))
        # I think I need to add +1 here because it's [start, end[
        # so like when you say in python3 range(1,5) you get a count until 4
        gaf_string.append(len(self.info))
        gaf_string.append(255)

        # identity = round(self.n_matches/len(self.info), 5)
        # I added some tags, as for alignment score (the score in the DP table)
        # dv for per-base sequence divergence (I think it's 1 - identity)
        # id for sequence identity
        # Maybe add tp:A:(P, S) for primary or secondary alignment
        # cm:i number of minimizers (maybe see how many seeds from the read hit that graph)
        # NM:i total numbers of mismatches and gaps (indels)
        # print(f"calculating the id_score from n matches {self.n_matches}")
        self.id_score = self.n_matches / float(len(self.info))
        gaf_string.append(f"NM:i:{self.n_indels + self.n_mismatches}")
        gaf_string.append(f"AS:i:{str(self.alignment_score)}")
        gaf_string.append(f"dv:f:{str(round(1-self.id_score, 4))}")
        gaf_string.append(f"id:f:{str(round(self.id_score, 4))}")
        # previous = (alignment.info[0]["cigar"], 1)
        previous = []
        cigar = "cg:Z:"
        cigar_symbols = ["I", "D", "=", "X"]
        # pdb.set_trace()
        for item in self.info:
            if not previous:
                previous = [item["type"], 1]

            elif item["type"] == previous[0]:
                previous[1] += 1
            else:
                cigar += str(previous[1]) + cigar_symbols[previous[0]]  # first letter (M, I, D)
                previous = [item["type"], 1]
        cigar += str(previous[1]) + cigar_symbols[previous[0]]

        gaf_string.append(cigar)

        # adding graph name as an extra tag
        gaf_string.append(f"GR:Z:{graph.name}")

        self.gaf = "\t".join([str(x) for x in gaf_string])


    cpdef list generate_vcf_records(self, Graph graph, str ref_seq,
                                    dict node_to_ref_start, set ref_node_set,
                                    str graph_name):
        """
        Generate VCF records from the alignment info.
        self.info must already be reversed (i.e. prepare_aa_gaf was called first).

        Variants are called when the query differs from its aligned path.
        Positions are reported in reference-path coordinates (1-based).

        For nodes NOT on the reference path, we anchor the variant at the
        fork ancestor's last reference position (VCF padding-base convention).

        Returns a list of tab-separated strings: POS\\tREF\\tALT\\tSAMPLE_NAME\\tVARTYPE
        where VARTYPE is one of SNV, INS, DEL.
        """
        cdef Node node
        cdef int node_id, ref_pos_0
        cdef list records = []
        cdef int vcf_pos
        cdef str ref_field, alt_field, rec, vartype
        cdef int ancestor_id, ancestor_last_pos, anchor_pos
        cdef str anchor_char, ref_char
        cdef int ref_nid, i, msa_col, mapped_ref

        if not self.info:
            return records

        # Cache for fork ancestor lookups
        fork_cache = dict()

        # Build MSA-column → reference-position mapping from ref path nodes
        msa_to_ref = dict()
        for ref_nid in ref_node_set:
            node = graph.nodes[ref_nid]
            for i in range(len(node.seq)):
                msa_to_ref[node.seq_pos + i] = node_to_ref_start[ref_nid] + i

        last_ref_anchor_pos = -1
        last_ref_anchor_char = ""

        pending_type = -1  # -1=none, 0=ins, 1=del, 3=mismatch
        pending_ref_pos = -1
        pending_ref_chars = ""
        pending_alt_chars = ""

        for item in self.info:
            node_id = item["node_id"]
            node_pos = item["node_pos"]
            op_type = item["type"]
            node_str = item["node_str"]
            read_str = item["read_str"]

            on_ref = node_id in ref_node_set

            if op_type == 2:  # match — flush pending, update anchor
                if pending_type != -1:
                    vcf_pos = pending_ref_pos + 1
                    ref_field = pending_ref_chars if pending_ref_chars else "."
                    alt_field = pending_alt_chars if pending_alt_chars else "."
                    if pending_type == 0:
                        vartype = "INS"
                    elif pending_type == 1:
                        vartype = "DEL"
                    else:
                        vartype = "SNV"
                    rec = f"{vcf_pos}\t{ref_field}\t{alt_field}\t{self.read_name}\t{vartype}"
                    records.append(rec)
                    pending_type = -1
                    pending_ref_pos = -1
                    pending_ref_chars = ""
                    pending_alt_chars = ""
                if on_ref:
                    last_ref_anchor_pos = node_to_ref_start[node_id] + node_pos
                    last_ref_anchor_char = node_str
                else:
                    node = graph.nodes[node_id]
                    msa_col = node.seq_pos + node_pos
                    mapped_ref = msa_to_ref.get(msa_col, -1)
                    if mapped_ref >= 0:
                        last_ref_anchor_pos = mapped_ref
                        last_ref_anchor_char = ref_seq[mapped_ref]
                continue

            if op_type == 3:  # mismatch (SNV)
                if pending_type != -1:
                    vcf_pos = pending_ref_pos + 1
                    ref_field = pending_ref_chars if pending_ref_chars else "."
                    alt_field = pending_alt_chars if pending_alt_chars else "."
                    if pending_type == 0:
                        vartype = "INS"
                    elif pending_type == 1:
                        vartype = "DEL"
                    else:
                        vartype = "SNV"
                    rec = f"{vcf_pos}\t{ref_field}\t{alt_field}\t{self.read_name}\t{vartype}"
                    records.append(rec)
                    pending_type = -1
                    pending_ref_pos = -1
                    pending_ref_chars = ""
                    pending_alt_chars = ""

                if on_ref:
                    ref_pos_0 = node_to_ref_start[node_id] + node_pos
                    ref_char = ref_seq[ref_pos_0]
                    pending_type = 3
                    pending_ref_pos = ref_pos_0
                    pending_ref_chars = ref_char
                    pending_alt_chars = read_str
                    last_ref_anchor_pos = ref_pos_0
                    last_ref_anchor_char = ref_char
                else:
                    node = graph.nodes[node_id]
                    msa_col = node.seq_pos + node_pos
                    mapped_ref = msa_to_ref.get(msa_col, -1)
                    if mapped_ref >= 0:
                        ref_char = ref_seq[mapped_ref]
                        pending_type = 3
                        pending_ref_pos = mapped_ref
                        pending_ref_chars = ref_char
                        pending_alt_chars = read_str
                        last_ref_anchor_pos = mapped_ref
                        last_ref_anchor_char = ref_char
                    else:
                        ancestor_id, ancestor_last_pos = self._find_fork_ancestor(
                            node_id, graph, ref_node_set, node_to_ref_start, fork_cache)
                        anchor_char = ref_seq[ancestor_last_pos] if ancestor_last_pos < len(ref_seq) else "."
                        pending_type = 3
                        pending_ref_pos = ancestor_last_pos
                        pending_ref_chars = anchor_char + node_str
                        pending_alt_chars = anchor_char + read_str

            elif op_type == 0:  # insertion
                if pending_type == 0:
                    pending_alt_chars += read_str
                else:
                    if pending_type != -1:
                        vcf_pos = pending_ref_pos + 1
                        ref_field = pending_ref_chars if pending_ref_chars else "."
                        alt_field = pending_alt_chars if pending_alt_chars else "."
                        if pending_type == 1:
                            vartype = "DEL"
                        else:
                            vartype = "SNV"
                        rec = f"{vcf_pos}\t{ref_field}\t{alt_field}\t{self.read_name}\t{vartype}"
                        records.append(rec)
                        pending_type = -1
                        pending_ref_pos = -1
                        pending_ref_chars = ""
                        pending_alt_chars = ""

                    if on_ref:
                        anchor_pos = node_to_ref_start[node_id] + node_pos
                        anchor_char = ref_seq[anchor_pos] if anchor_pos < len(ref_seq) else ""
                    elif last_ref_anchor_pos >= 0:
                        anchor_pos = last_ref_anchor_pos
                        anchor_char = last_ref_anchor_char
                    else:
                        node = graph.nodes[node_id]
                        msa_col = node.seq_pos + node_pos
                        mapped_ref = msa_to_ref.get(msa_col, -1)
                        if mapped_ref >= 0:
                            anchor_pos = mapped_ref
                            anchor_char = ref_seq[anchor_pos] if anchor_pos < len(ref_seq) else ""
                        else:
                            ancestor_id, ancestor_last_pos = self._find_fork_ancestor(
                                node_id, graph, ref_node_set, node_to_ref_start, fork_cache)
                            anchor_pos = ancestor_last_pos
                            anchor_char = ref_seq[anchor_pos] if anchor_pos < len(ref_seq) else ""

                    pending_type = 0
                    pending_ref_pos = anchor_pos
                    pending_ref_chars = anchor_char
                    pending_alt_chars = anchor_char + read_str

            elif op_type == 1:  # deletion
                if on_ref:
                    ref_pos_0 = node_to_ref_start[node_id] + node_pos
                    if pending_type == 1 and pending_ref_pos >= 0:
                        pending_ref_chars += ref_seq[ref_pos_0]
                    else:
                        if pending_type != -1:
                            vcf_pos = pending_ref_pos + 1
                            ref_field = pending_ref_chars if pending_ref_chars else "."
                            alt_field = pending_alt_chars if pending_alt_chars else "."
                            if pending_type == 0:
                                vartype = "INS"
                            else:
                                vartype = "SNV"
                            rec = f"{vcf_pos}\t{ref_field}\t{alt_field}\t{self.read_name}\t{vartype}"
                            records.append(rec)
                            pending_type = -1
                            pending_ref_pos = -1
                            pending_ref_chars = ""
                            pending_alt_chars = ""

                        if last_ref_anchor_pos >= 0:
                            anchor_pos = last_ref_anchor_pos
                            anchor_char = last_ref_anchor_char
                        else:
                            anchor_pos = ref_pos_0 - 1 if ref_pos_0 > 0 else 0
                            anchor_char = ref_seq[anchor_pos]

                        pending_type = 1
                        pending_ref_pos = anchor_pos
                        pending_ref_chars = anchor_char + ref_seq[ref_pos_0]
                        pending_alt_chars = anchor_char

        # Final flush
        if pending_type != -1:
            vcf_pos = pending_ref_pos + 1
            ref_field = pending_ref_chars if pending_ref_chars else "."
            alt_field = pending_alt_chars if pending_alt_chars else "."
            if pending_type == 0:
                vartype = "INS"
            elif pending_type == 1:
                vartype = "DEL"
            else:
                vartype = "SNV"
            rec = f"{vcf_pos}\t{ref_field}\t{alt_field}\t{self.read_name}\t{vartype}"
            records.append(rec)

        return records

    def _find_fork_ancestor(self, int nid, Graph graph, set ref_node_set,
                            dict node_to_ref_start, dict fork_cache):
        """
        Given a node NOT on the reference path, walk backwards through in_nodes
        (BFS) to find the nearest ancestor that IS on the reference path.
        Returns (ancestor_node_id, ancestor_last_ref_pos_0based).
        """
        cdef Node ancestor_node
        cdef Node cur_node
        if nid in fork_cache:
            return fork_cache[nid]
        visited = set()
        bfs_queue = [nid]
        while bfs_queue:
            cur = bfs_queue.pop(0)
            if cur in visited:
                continue
            visited.add(cur)
            if cur != nid and cur in ref_node_set:
                ancestor_node = graph.nodes[cur]
                last_pos = node_to_ref_start[cur] + len(ancestor_node.seq) - 1
                fork_cache[nid] = (cur, last_pos)
                return (cur, last_pos)
            cur_node = graph.nodes[cur]
            for parent_id in cur_node.in_nodes:
                if parent_id not in visited:
                    bfs_queue.append(parent_id)
        fork_cache[nid] = (nid, 0)
        return (nid, 0)
