
#' Convert CFGraph to Static Single-Assignment Form
#'
#' This function converts code in a control flow graph (CFG) to static
#' single-assignment form.
#'
#' @param cfg (CFGraph) A control flow graph.
#' @param in_place (logical) Don't copy CFG before conversion?
#'
#' @return The control flow graph as a CFGraph object, with the code in each
#' block converted to SSA form.
#'
#' @export
to_ssa = function(cfg, in_place = FALSE) {
  if (!in_place)
    cfg = cfg$copy()

  # TODO: make this function's implementation more idiomatic.
  dom_t = dom_tree(cfg)
  dom_f = dom_frontier(cfg, dom_t)

  globals = character(0) # symbols used in more than one block
  assign_blocks = list() # blocks where global symbols are assigned

  for (i in seq_along(cfg)) {
    block = cfg[[i]]
    varkill = character(0)

    for (node in block$body) {
      # TODO: Ignoring all but assignments may skip some reads; do we need to
      # add these reads to the globals set?
      if (!inherits(node, "Assign"))
        next

      # Add all read variables not in varkill to the globals set.
      reads = collect_reads(node$read)
      reads = setdiff(reads, varkill)
      globals = union(globals, reads)

      # Add write variable to the kill set and add current block to its blocks
      # set.
      # FIXME: Does __retval__ need to be ignored?
      name = node$write$name
      varkill = union(varkill, name)

      # Check that assign_blocks[[name]] exists.
      if (is.null(assign_blocks[[name]])) {
        assign_blocks[[name]] = i
      } else {
        assign_blocks[[name]] = union(assign_blocks[[name]], i)
      }
    }
  } # end for

  # Insert phi-functions.
  for (name in globals) {
    # Add phi-function to dominance frontier for each block with an assignment.
    worklist = assign_blocks[[name]]
    for (b in worklist) {
      for (d in dom_f[[b]]) {
        if (has_phi(cfg[[d]], name))
          next

        phi = Phi$new(name)
        cfg[[d]]$append(phi)
        worklist = union(worklist, d)
      } # end for d
    }
  } # end for name

  # Rename variables.
  ssa_rename(cfg$entry, cfg, dom_t)

  return (cfg)
}


#' Rename CFG Variables with SSA Names
#'
#' This function renames variables in the basic blocks of a CFG with their SSA
#' names.
#'
#' Generally, this function should only be called from \code{to_ssa()}.
#'
#' @param block (integer) Identifier of a basic block in the CFG.
#' @param cfg (CFGraph) A control-flow graph.
#' @param dom_t (integer) The dominator tree for the CFG.
#' @param ns (NameStack) A stateful object used by the renaming algorithm.
#'
ssa_rename = function(block, cfg, dom_t, ns = NameStack$new()) {
  # Rewrite LHS of phi-functions in this block.
  lapply(cfg[[block]]$phi, function(phi) {
    phi$write = ns$new_name(phi$base)
  })

  # Rewrite operations in this block.
  ssa_rename_ast(cfg[[block]]$body, ns)

  # Rewrite terminator in this block.
  term = cfg[[block]]$terminator
  if (inherits(term, "BranchInst") && !is.null(term$condition)) {
    ssa_rename_ast(term$condition, ns)
  } else if (inherits(term, "IterateInst")) {
    ssa_rename_ast(term$iter, ns)
  }

  # Rewrite RHS of phi-functions in successors.
  for (id in cfg[[block]]$successors) {
    lapply(cfg[[id]]$phi, function(phi) {
      name = ns$get_name(phi$base)
      phi$set_read(block, name)
    })
  }

  # Descend to blocks dominated by this block (children in dom tree).
  ns$save_locals()

  children = setdiff(which(dom_t == block), block)
  lapply(children, ssa_rename, cfg, dom_t, ns)

  # End lifetimes of variables defined in this block.
  ns$clear_locals()
}


#' Rename AST Variables with SSA Names
#'
#' This function renames variables in an AST with their SSA names.
#'
#' Generally, this function should only be called from \code{ssa_rename()}.
#'
#' @param node (ASTNode) An abstract syntax tree.
#' @param ns (NameStack) A stateful object used by the renaming algorithm.
#'
ssa_rename_ast = function(node, ns) {
  # FIXME: This doesn't change function names.
  # Rename all AST elements.
  UseMethod("ssa_rename_ast")
}

#' @export
ssa_rename_ast.Assign = function(node, ns) {
  ssa_rename_ast(node$read, ns)
  node$write$name = ns$new_name(node$write$name)
  return (node)
}

#' @export
ssa_rename_ast.Call = function(node, ns) {
  lapply(node$args, ssa_rename_ast, ns)
  return (node)
}

#' @export
ssa_rename_ast.Symbol = function(node, ns) {
  node$name = ns$get_name(node$name)
  return (node)
}

#' @export
ssa_rename_ast.Literal = function(node, ns) return (node)

#' @export
ssa_rename_ast.list = function(node, ns) {
  lapply(node, ssa_rename_ast, ns)
  return (node)
}