import React, { useState, Fragment, useEffect } from "react";

import {
  Button,
  Segment,
  Label,
  Icon,
  Message,
  Header,
  Divider,
  Accordion,
  Breadcrumb,
  Table,
  Form,
  Checkbox,
  Popup,
  Modal,
} from "semantic-ui-react";
import "semantic-ui-css/semantic.min.css";
import "../Styles/default";

import Breadcrumbs from "../Shared/Breadcrumb";
import { Controller, useForm } from "react-hook-form";
import { DateInput } from "semantic-ui-calendar-react";
import MessageBox from "../Shared/MessageBox";
import axios from "axios";
import { tableSortReducer } from "../Shared/TableSort";
import { _ } from "lodash";

export default function FinalDelivery({
  sl_states,
  nri_states,
  projects,
  token,
}) {
  const [project, setProject] = useState("SL");
  const [stateOptions, setStateOptions] = useState(sl_states);
  const [message, setMessage] = useState(null);
  const [validatedObj, setValidatedObj] = useState(null);
  const [result, setResult] = useState(null);

  console.log("FinalDelivery", {
    sl_states,
    nri_states,
    projects,
  });

  useEffect(() => {
    console.error({ project });
    if (project === "SL") {
      setStateOptions(sl_states);
    } else if (project === "NRI") {
      setStateOptions(nri_states);
    }
  }, [project]);

  const resetForm = () => {
    setValidatedObj(null);
    setResult(null);
  };

  return (
    <div>
      <Breadcrumbs>
        <Breadcrumb.Section>Exports</Breadcrumb.Section>
        <Breadcrumb.Divider />
        <Breadcrumb.Section>Final Delivery</Breadcrumb.Section>
        {project && (
          <>
            <Breadcrumb.Divider />
            <Breadcrumb.Section>{project}</Breadcrumb.Section>
          </>
        )}
        <Breadcrumb.Divider />
        <Breadcrumb.Section>
          Generate Metadata and Assign Packing Slip Number
        </Breadcrumb.Section>
      </Breadcrumbs>
      <Divider />

      {message && (
        <MessageBox
          status={message.status}
          title={message.title}
          message={message.text}
        />
      )}

      {!result && (
        <ValidateFormSL
          projects={projects}
          project={project}
          setProject={setProject}
          states={stateOptions}
          setValidatedObj={setValidatedObj}
          setResult={setResult}
          token={token}
          setMessage={setMessage}
        />
      )}

      {result && (
        <FinalDeliveryFormNRISL
          project={project}
          result={result}
          validatedObj={validatedObj}
          token={token}
          resetForm={resetForm}
          setMessage={setMessage}
        />
      )}
    </div>
  );
}

function ValidateFormSL({
  projects,
  project,
  setProject,
  token,
  states,
  setValidatedObj,
  setResult,
  setMessage,
}) {
  const {
    handleSubmit,
    reset,
    setValue,
    register,
    control,
    formState: { errors },
  } = useForm();

  const handleChange = (e, { name, value }) => {
    if (name === "project") setProject(value);
    setValue(name, value);
  };

  const onValidationSubmit = (data) => {
    // console.error("onValidationSubmit", data);

    setMessage({
      status: "Loading",
      title: "Processing Request",
      text: "Please do not leave or close page until request is finished",
    });

    window.onbeforeunload = () => {
      return "Leaving may interrupt the import process. Please wait til the operation is complete";
    };

    axios
      .post(`/final_delivery/generate_metadata_and_assign_psn/validate`, {
        authenticity_token: token,
        input_directory: data.input_directory,
        project: data.project,
        state_id: data.state,
      })
      .then(({ data }) => {
        console.log("submit response", data);

        if (data.pass) {
          setResult(data.result);
          setValidatedObj(data);
          setMessage({
            status: "Notice",
            title: "Validated TIles",
            text: data.message,
          });
        } else {
          // Set message
          setMessage({
            status: "Error",
            text: data.message,
          });
        }

        window.onbeforeunload = null;
      })
      .catch((err) => {
        console.log(err);
        setMessage({
          status: "Error",
          text: "Something went wrong",
        });
        window.onbeforeunload = null;
      });
  };

  return (
    <Form>
      <MessageBox
        status="Notice"
        title="Important"
        message={
          <span>
            This is the first step of Final Delivery that will verify your Text
            File and Supplied Path. Input directory must be nested under{" "}
            <b>P:\Vol_1</b>.
          </span>
        }
      />
      <Divider />

      <Form.Group widths="equal">
        <Controller
          name={"project"}
          control={control}
          rules={{ required: "Required" }}
          defaultValue={project}
          render={({ field: { name, value, defaultValue } }) => (
            <Form.Select
              fluid
              search
              selection
              name={name}
              data-value={value}
              label={"Project"}
              required={true}
              value={value || ""}
              defaultValue={defaultValue}
              onChange={handleChange}
              autoComplete="off"
              options={projects.map((record) => {
                return {
                  key: record,
                  text: record,
                  value: record,
                };
              })}
              error={
                errors["project"]
                  ? {
                      content: errors["project"].message,
                      pointing: "above",
                    }
                  : false
              }
            />
          )}
        />
        <Controller
          name={"state"}
          control={control}
          rules={{ required: "Required" }}
          render={({ field: { name, value } }) => (
            <Form.Select
              fluid
              search
              selection
              clearable
              name={name}
              data-value={value}
              label={"State"}
              required={true}
              value={value}
              onChange={handleChange}
              autoComplete="off"
              options={states.map((record) => {
                return {
                  key: record.id,
                  value: record.id,
                  text: record.name,
                };
              })}
              error={
                errors["state"]
                  ? {
                      content: errors["state"].message,
                      pointing: "above",
                    }
                  : false
              }
            />
          )}
        />
      </Form.Group>

      <Form.Group widths="equal">
        <Controller
          name={"input_directory"}
          control={control}
          rules={{ required: "Required" }}
          render={({ field: { name, onBlur, onChange, value } }) => (
            <Form.Input
              fluid
              label="Input Directory"
              autoComplete="off"
              name={name}
              required={true}
              onBlur={onBlur}
              onChange={onChange}
              value={value || ""}
              error={
                errors["input_directory"] && errors["input_directory"].message
              }
            />
          )}
        />
      </Form.Group>

      <Divider />

      <Button
        primary
        floated="right"
        type="button"
        onClick={handleSubmit(onValidationSubmit)}
      >
        Submit
      </Button>
      <Button secondary floated="right" type="button" onClick={() => reset()}>
        Reset
      </Button>
      <div style={{ clear: "both" }} />
    </Form>
  );
}

function FinalDeliveryFormNRISL({
  project,
  result,
  validatedObj,
  token,
  resetForm,
  setMessage,
}) {
  if (!result) return null;

  const [counties, setCounties] = useState([]);
  const [accordionState, setAccordionState] = useState(true);
  const [deliveryType, setDeliveryType] = useState("Production");
  const [coverage, setCoverage] = useState(null);
  const [submitObj, setSubmitObj] = useState(null);
  const [confirmModal, showConfirmModal] = useState(false);
  const [confirmation, setConfirmation] = useState(false);
  const [submitted, setSubmitted] = useState(false);

  const [state, dispatch] = React.useReducer(tableSortReducer, {
    column: null,
    data: result,
    direction: null,
  });
  const { column, data, direction } = state;

  const {
    handleSubmit,
    reset,
    setValue,
    register,
    unregister,
    control,
    getValues,
    formState: { errors },
  } = useForm({
    defaultValues: {
      delivery_type: "Production",
      project: project,
    },
  });

  console.log("FinalDeliveryFormNRISL", {
    result,
    validatedObj,
    coverage,
    deliveryType,
    submitted,
    values: getValues(),
  });

  useEffect(() => {
    dispatch({ type: "CHANGE_SORT", column: "county_name" });

    // Set default values
    setValue("ship_date", moment().format("MM/DD/YYYY"));
  }, []);

  useEffect(() => {
    console.log("CONFIRMATION USEEFFECT", confirmation);
    if (confirmation) {
      showConfirmModal(false);
      submitForm(submitObj);
    }
  }, [confirmation]);

  useEffect(() => {
    if (deliveryType === "Pre-Production") {
      // Remove the Ship Date and PackingSlip fields
      unregister("ship_date");
      unregister("packing_slip_name");
    } else {
      register("ship_date");
      register("packing_slip_name");
    }
  }, [deliveryType]);

  const checkboxChange = (e, { value, checked }) => {
    // console.log("checkboxChange", { value, checked });
    if (counties.includes(value)) {
      setCounties([...counties].filter((county) => county != value));
    } else {
      var arr = [...counties];
      arr.push(value);
      setCounties(arr);
    }
  };

  const checkAll = (e, { checked }) => {
    if (checked) {
      // detect the coverage type
      if (coverage === "Full Counties") {
        setCounties(
          result
            .filter(
              (record) =>
                record.total_tiles === record.ready_to_ship &&
                record.ready_to_ship === record.folder_count
            )
            .map((record) => record.id)
        );
      } else {
        setCounties(
          result
            .filter((record) => record.ready_to_ship > 0)
            .map((record) => record.id)
        );
      }
    } else {
      setCounties([]);
    }
  };

  const handleChange = (e, { name, value }) => {
    setValue(name, value);
  };

  const typeChange = (e, { value }) => {
    setValue("delivery_type", value);
    setDeliveryType(value);
  };

  const coverageChange = (e, { value }) => {
    setValue("coverage", value);
    setCoverage(value);

    // clear the counties so the user re-selects the correct counties
    setCounties([]);
  };

  const checkCompleted = () => {
    // Iterate all the results and check if the Tiles in Folders and shipped Tiles match the Total County Tiles
    var records = result.filter(
      (record) =>
        record.total_tiles === record.ready_to_ship &&
        record.ready_to_ship === record.folder_count
    );

    setCounties(records.map((record) => record.id));
  };

  const onFinalSubmit = (data) => {
    console.error("onFinalSubmit", { data, counties });

    setConfirmation(false);

    // If no counties then reject it
    if (counties.length == 0) {
      setMessage({
        status: "Error",
        title: "Invalid Submission",
        text: "Select a minimum of one County Checkbox and try again",
      });
      return false;
    }

    setSubmitObj({
      project: project,
      input_directory: validatedObj.input_directory,
      packing_slip_name: data.packing_slip_name,
      count: validatedObj.count,
      state_id: validatedObj.state_id,
      counties: counties,
      delivery_type: data.delivery_type,
      coverage: data.coverage,
      authenticity_token: token,
    });

    // if delivery_type is production and coverage is partial counties then launch modal
    if (
      data.delivery_type === "Production" &&
      data.coverage === "Partial Counties"
    ) {
      showConfirmModal(true);
    } else {
      setConfirmation(true);
    }
  };

  const submitForm = (data) => {
    console.error("submitForm", data);

    setSubmitted(true);

    // If the delivery type is production adn coverage is partial counties and no confirmation then throw error
    if (
      data.delivery_type === "Production" &&
      data.coverage === "Partial Counties" &&
      !confirmation
    ) {
      setMessage({
        status: "Error",
        title: "Invalid Submission",
        text: "Select a minimum of one County Checkbox and try again",
      });
      return false;
    }

    setMessage({
      status: "Loading",
      title: "Processing Request",
      text: "Please do not leave or close page until request is finished",
    });

    window.onbeforeunload = () => {
      return "Leaving may interrupt the import process. Please wait til the operation is complete";
    };

    axios
      .post(
        `/final_delivery/generate_metadata_and_assign_psn/execute`,
        submitObj
      )
      .then(({ data }) => {
        console.log("submit response", data);

        // Set message
        setMessage({
          status: data.state ? "Success" : "Error",
          text: data.message,
        });

        if (data.state) {
          resetForm();
          setCounties([]);
          setConfirmation(false);
        }

        setSubmitted(true);

        window.onbeforeunload = null;
      })
      .catch((err) => {
        console.error("Error", err);

        setSubmitted(false);

        setMessage({
          status: "Error",
          text: "Something went wrong",
        });
        window.onbeforeunload = null;
      });
  };

  const renderCheckbox = (record) => {
    // Return no checkbox if there is not a delivery type
    if (!coverage) return false;

    // Production
    if (
      coverage === "Full Counties" &&
      record.total_tiles === record.ready_to_ship &&
      record.ready_to_ship === record.folder_count
    ) {
      return true;
    }

    // Pre-Production
    if (coverage === "Partial Counties" && record.ready_to_ship > 0) {
      return true;
    }

    return false;
  };

  return (
    <Fragment>
      {/* {coverage === "Partial Counties" && (
        <MessageBox
          status={"Warning"}
          title={""}
          message={
            "Proceeding would break the requirements of the USDA Contract. This is commonly used at the end of the contract year when the USDA requests all available data regardless if the county is fully completed. Make sure you know what you are doing!"
          }
        />
      )} */}
      {deliveryType === "Pre-Production" && (
        <MessageBox
          title={"Pre-Production Notice"}
          message={
            "Proceeding the selected counties will be processed but not updated in the database to show that they have been actually shipped. There will need to be another Final Delivery Process ran to mark it as Shipped."
          }
        />
      )}
      {(coverage == "Partial Counties" ||
        deliveryType === "Pre-Production") && <Divider />}

      <Modal basic size="small" open={confirmModal}>
        <Header icon>
          <Icon name="warning" style={{ marginBottom: ".5em" }} />
          Warning! About to submit Partial Counties in Production Packing Slip
        </Header>
        <Modal.Content>
          <p>
            Proceeding would break the requirements of the USDA Contract. This
            is commonly used at the end of the contract year when the USDA
            requests all available data regardless if the county is fully
            completed. Make sure you know what you are doing!
          </p>
        </Modal.Content>
        <Modal.Actions>
          <Button
            basic
            color="red"
            inverted
            onClick={() => showConfirmModal(false)}
          >
            <Icon name="remove" /> Cancel
          </Button>
          <Button color="green" inverted onClick={() => setConfirmation(true)}>
            <Icon name="checkmark" /> Proceed
          </Button>
        </Modal.Actions>
      </Modal>

      <Form>
        <Accordion fluid styled>
          <Accordion.Title
            active={accordionState}
            onClick={() => setAccordionState(!accordionState)}
          >
            <Icon name="dropdown" />
            Execute Process
          </Accordion.Title>
          <Accordion.Content active={accordionState}>
            {deliveryType === "Production" && (
              <Form.Group widths="equal">
                <Form.Field error={errors.hasOwnProperty("ship_date")}>
                  <div className="calendar-input">
                    <Controller
                      name={"ship_date"}
                      control={control}
                      rules={{
                        required: "Required",
                      }}
                      render={({ field: { name, value } }) => (
                        <DateInput
                          closable
                          clearable
                          name={name}
                          label={"Shipping Date"}
                          required={true}
                          value={value || ""}
                          dateFormat="MM/DD/YYYY"
                          iconPosition="left"
                          onChange={handleChange}
                          autoComplete="off"
                        />
                      )}
                    />
                  </div>
                  {errors[`ship_date`] && (
                    <Label pointing prompt>
                      {errors[`ship_date`].message}
                    </Label>
                  )}
                </Form.Field>
                <Controller
                  name={"packing_slip_name"}
                  control={control}
                  rules={{ required: "Required" }}
                  render={({ field: { name, onChange, value } }) => (
                    <Form.Input
                      fluid
                      label={"Packing Slip Name (Must be a unique Name)"}
                      autoComplete="off"
                      name={name}
                      required={true}
                      onBlur={onChange}
                      onChange={onChange}
                      value={value || ""}
                      error={errors[name] && errors[name].message}
                    />
                  )}
                />
              </Form.Group>
            )}

            <Form.Group widths="equal">
              <Controller
                name={"delivery_type"}
                control={control}
                rules={{ required: "Required" }}
                render={({ field: { name, value } }) => (
                  <Form.Select
                    fluid
                    search
                    selection
                    clearable
                    name={name}
                    data-value={value}
                    label={"Delivery Type"}
                    required={true}
                    defaultValue={deliveryType}
                    value={value}
                    onChange={typeChange}
                    autoComplete="off"
                    options={["Production", "Pre-Production"].map((value) => {
                      return {
                        key: value,
                        value: value,
                        text: value,
                      };
                    })}
                    error={
                      errors[name]
                        ? {
                            content: errors[name].message,
                            pointing: "above",
                          }
                        : false
                    }
                  />
                )}
              />
              <Controller
                name={"coverage"}
                control={control}
                rules={{ required: "Required" }}
                render={({ field: { name, value } }) => (
                  <Form.Select
                    fluid
                    search
                    selection
                    clearable
                    name={name}
                    data-value={value}
                    label={"Coverage Type"}
                    required={true}
                    value={value}
                    onChange={coverageChange}
                    autoComplete="off"
                    options={["Full Counties", "Partial Counties"].map(
                      (value) => {
                        return {
                          key: value,
                          value: value,
                          text: value,
                        };
                      }
                    )}
                    error={
                      errors[name]
                        ? {
                            content: errors[name].message,
                            pointing: "above",
                          }
                        : false
                    }
                  />
                )}
              />
            </Form.Group>
          </Accordion.Content>
        </Accordion>
        <Divider />
        <Table unstackable sortable celled striped textAlign="center">
          <Table.Header>
            <Table.Row>
              {coverage && (
                <Table.HeaderCell collapsing>
                  <Checkbox
                    onChange={checkAll}
                    checked={result.length === counties.length ? true : false}
                  />
                </Table.HeaderCell>
              )}
              <Table.HeaderCell
                sorted={column === "county_name" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "county_name" })
                }
              >
                County
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "state_name" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "state_name" })
                }
              >
                State
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "full_fips" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "full_fips" })
                }
              >
                FIPS Code
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "total_tiles" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "total_tiles" })
                }
              >
                Total Tiles in County
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "ready_to_ship" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "ready_to_ship" })
                }
              >
                Ready to Ship
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "folder_count" ? direction : null}
                onClick={() =>
                  dispatch({ type: "CHANGE_SORT", column: "folder_count" })
                }
              >
                Tiles in Folder
              </Table.HeaderCell>
              <Table.HeaderCell
                sorted={column === "total_shipped_tiles" ? direction : null}
                onClick={() =>
                  dispatch({
                    type: "CHANGE_SORT",
                    column: "total_shipped_tiles",
                  })
                }
              >
                Shipped Tiles
              </Table.HeaderCell>
            </Table.Row>
          </Table.Header>
          <Table.Body>
            {data.map((record) => {
              return (
                <Table.Row key={record.id}>
                  {coverage && (
                    <Table.Cell collapsing>
                      {renderCheckbox(record) && (
                        <Checkbox
                          value={record.id}
                          checked={counties.includes(record.id)}
                          onChange={checkboxChange}
                        />
                      )}
                    </Table.Cell>
                  )}
                  <Table.Cell singleLine>{record.county_name}</Table.Cell>
                  <Table.Cell singleLine>{record.state_name}</Table.Cell>
                  <Table.Cell singleLine>{record.full_fips}</Table.Cell>
                  <Table.Cell singleLine>{record.total_tiles}</Table.Cell>
                  <Table.Cell
                    positive={record.total_tiles === record.ready_to_ship}
                    negative={record.total_tiles != record.ready_to_ship}
                  >
                    {record.ready_to_ship}
                  </Table.Cell>
                  <Table.Cell
                    positive={record.total_tiles === record.folder_count}
                    negative={record.total_tiles != record.folder_count}
                    singleLine
                  >
                    {record.folder_count}
                  </Table.Cell>
                  <Table.Cell
                    positive={record.total_shipped_tiles === record.total_tiles}
                    negative={record.total_shipped_tiles != record.total_tiles}
                    singleLine
                  >
                    {record.total_shipped_tiles}
                  </Table.Cell>
                </Table.Row>
              );
            })}
          </Table.Body>
        </Table>

        <Divider />

        <Button floated="left" type="button" onClick={checkCompleted}>
          Select all Completed Counties
        </Button>

        <Button
          primary
          floated="right"
          type="button"
          loading={submitted}
          disabled={counties.length === 0 || submitted}
          onClick={handleSubmit(onFinalSubmit)}
        >
          Submit
        </Button>
        <Button
          secondary
          floated="right"
          type="button"
          onClick={() => {
            reset();
            setCounties([]);
          }}
        >
          Reset
        </Button>
        <div style={{ clear: "both" }} />
        <br />
        <br />
      </Form>
    </Fragment>
  );
}
